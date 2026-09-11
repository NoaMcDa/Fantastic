// Browser half of the Keto Lens OCR firewall.
//
// Wraps tesseract.js in the smallest possible promise-returning surface so the
// Dart side (TesseractJsTextRecognizer) needs one `dart:js_interop` binding and
// never learns what engine is behind it.
//
// Everything is served from this directory. tesseract.js defaults to fetching
// its core from jsDelivr and its language data from tessdata.projectnaptha.com;
// both are network calls at scan time, which Epic #10's first architectural
// invariant forbids, and both would regress the property design/web_support.md
// 7 records as verified - that the app makes zero external requests. The
// explicit workerPath / corePath / langPath below are what keep that true, and
// they are the same reasoning that put --no-web-resources-cdn on the CanvasKit
// build.
//
// Only one core is ever downloaded by a given browser: tesseract.js feature-
// detects relaxed SIMD, then SIMD, then plain, and requests the one variant it
// can run. The other two sit in the deploy unused.
(function () {
  'use strict';

  var BASE = 'tesseract/';
  // The models are NOT duplicated here. Flutter serves the app's asset bundle
  // under assets/, so assets/tessdata/heb.traineddata and eng.traineddata -
  // the same files the desktop FFI half unpacks and the mobile plugin reads -
  // are reachable at this URL. One copy of each for all six platforms, and no
  // second copy to drift out of step with the first.
  var LANG_PATH = 'assets/assets/tessdata';
  // Hebrew plus English. The Hebrew model cannot reliably read a column of
  // bare Latin digits - on a real Israeli panel it returned 218/9/2/43/9/308
  // where the label printed 238/10.9/41.2/7/3.3/368 - and English beside it
  // returns every figure exactly. Both models are served from LANG_PATH, so
  // this costs a second same-origin fetch and no external request.
  // TessdataBundle (the native half) carries the full reasoning, including
  // what it costs on pointed Hebrew.
  var LANG = 'heb+eng';

  // Mirrors OcrImagePrep in lib/features/keto_lens/data/adapters/. JavaScript
  // cannot import a Dart constant, so these four values are duplicated and
  // must be changed together. See that file for why each exists.
  var MIN_WIDTH = 1100;
  var TARGET_WIDTH = 1600;
  var MAX_UPSCALE = 4;
  var MAX_EDGE = 4500;
  var MAX_PIXELS = 20000000;
  var ASSUMED_DPI = '300';

  var worker = null;      // the resolved worker, once ready
  var starting = null;    // in-flight createWorker promise, so two scans share one

  function available() {
    return typeof Tesseract !== 'undefined';
  }

  function start() {
    if (worker) return Promise.resolve(worker);
    if (starting) return starting;
    if (!available()) {
      return Promise.reject(new Error('tesseract.js did not load'));
    }
    // oem 1 = LSTM_ONLY, which is what the -lstm cores implement and what the
    // tessdata_fast models are trained for.
    starting = Tesseract.createWorker(LANG, 1, {
      workerPath: BASE + 'worker.min.js',
      corePath: BASE,
      langPath: LANG_PATH,
      // The asset is served uncompressed; without this tesseract.js would ask
      // for heb.traineddata.gz and get Flutter's index.html back as a 200.
      gzip: false,
      // Keep the engine quiet; a scan logs nothing to the console.
      logger: function () {},
      errorHandler: function () {},
    }).then(function (w) {
      worker = w;
      starting = null;
      return w;
    }, function (e) {
      starting = null;
      throw e;
    });
    return starting;
  }

  // `src` is whatever the picker handed Dart: a blob: URL on web, since
  // image_picker_for_web has no filesystem to return a path from. Keeping it a
  // String is what lets the pipeline's boundary type stay a String on every
  // platform (M6 convention 2).
  // The scale factor to apply before recognition, or 1 to leave the image
  // alone. Same rule as OcrImagePrep.scaleFactor in Dart.
  function scaleFactor(w, h) {
    if (!(w > 0) || !(h > 0)) return 1;
    var f = w >= MIN_WIDTH ? 1 : Math.min(TARGET_WIDTH / w, MAX_UPSCALE);
    var longest = Math.max(w, h);
    if (longest * f > MAX_EDGE) f = MAX_EDGE / longest;
    if (w * f * (h * f) > MAX_PIXELS) f = Math.sqrt(MAX_PIXELS / (w * h));
    return f > 0 && isFinite(f) ? f : 1;
  }

  // Draws `src` onto a canvas at the corrected size, or resolves to `src`
  // untouched when nothing needs doing.
  //
  // tesseract.js accepts a canvas directly, so this hands over pixels rather
  // than a re-encoded blob - no second decode, and no image/* round trip.
  // Any failure resolves to the original source: a scan that might have read
  // better beats a scan that did not happen.
  function prepare(src) {
    if (typeof createImageBitmap !== 'function') return Promise.resolve(src);
    return fetch(src)
      .then(function (r) { return r.blob(); })
      .then(function (b) { return createImageBitmap(b); })
      .then(function (bitmap) {
        var f = scaleFactor(bitmap.width, bitmap.height);
        if (f === 1) {
          bitmap.close && bitmap.close();
          return src;
        }
        var canvas = document.createElement('canvas');
        canvas.width = Math.round(bitmap.width * f);
        canvas.height = Math.round(bitmap.height * f);
        var ctx = canvas.getContext('2d', { willReadFrequently: true });
        // Smoothing on, highest quality: enlarging glyphs with nearest
        // neighbour stair-steps exactly the stroke edges the LSTM reads.
        //
        // Not exactly equivalent to the native half, and it cannot be. That
        // one picks package:image's linear kernel by measurement; a canvas
        // exposes only a quality hint and the browser chooses the kernel. So
        // the two paths agree on size and on colour, and differ in resampling
        // by however much the browser's implementation differs.
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = 'high';
        ctx.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
        bitmap.close && bitmap.close();

        // Flatten to grey. On the native side this was not cosmetic: handed a
        // colour buffer, Tesseract read every Hebrew row of the test label and
        // *not one digit*, and flattening the alpha channel alone did not help
        // - only true single-channel grey did. A canvas cannot carry one
        // channel, so this writes r=g=b=luma with an opaque alpha, which is
        // the nearest equivalent the platform allows.
        //
        // UNVERIFIED IN A BROWSER. There is no browser in the repository that
        // produced this, so whether the wasm build shares the native build's
        // sensitivity to colour is unknown. It is applied because it matches
        // what was measured to work and cannot plausibly hurt.
        try {
          var pixels = ctx.getImageData(0, 0, canvas.width, canvas.height);
          var d = pixels.data;
          for (var i = 0; i < d.length; i += 4) {
            // Rec. 601 luma, the same weighting package:image uses.
            var y = (d[i] * 299 + d[i + 1] * 587 + d[i + 2] * 114) / 1000;
            d[i] = d[i + 1] = d[i + 2] = y;
            d[i + 3] = 255;
          }
          ctx.putImageData(pixels, 0, 0);
        } catch (e) {
          // A tainted canvas cannot be read back. The scan proceeds in
          // colour rather than not at all.
        }
        return canvas;
      })
      .catch(function () { return src; });
  }

  function recognise(src) {
    return Promise.all([start(), prepare(src)]).then(function (both) {
      var w = both[0];
      // psm 4 - "a single column of text of variable sizes". This was 6
      // ("a single uniform block") until a user scanned a real Israeli
      // nutrition panel and the app read six of its nine rows as punctuation
      // rubble. A bordered table with numbers in one column and Hebrew labels
      // in another is what mode 6 flattens; mode 4 keeps each row with its
      // own number.
      //
      // user_defined_dpi - Tesseract estimates resolution when the image does
      // not declare one, and on that same panel it estimated 631 dpi and then
      // downscaled internally on the strength of the guess. Declaring a value
      // stops the guess.
      //
      // preserve_interword_spaces is deliberately NOT set. The documentation
      // reads as though 1 is the safer choice, and for Latin it is - but on
      // RTL Hebrew it *removes* spaces rather than preserving them:
      // "53.8 גרם" comes back as "53.8גרם" and "משומשום מלא" as
      // "משומשוםמלא". Measured on both engines, same result; see
      // design/m6_platform_research.md.
      return w.setParameters({
        tessedit_pageseg_mode: '4',
        user_defined_dpi: ASSUMED_DPI,
      }).then(function () { return w.recognize(both[1]); });
    }).then(function (result) {
      return (result && result.data && result.data.text) || '';
    });
  }

  window.fantasticOcr = {
    available: available,
    recognise: recognise,
    // Lets the UI pay the ~1s model load before the user takes a photo rather
    // than inside the scan. Failure here is not fatal - recognise() retries.
    warmUp: function () { return start().then(function () { return true; }, function () { return false; }); },
  };
})();
