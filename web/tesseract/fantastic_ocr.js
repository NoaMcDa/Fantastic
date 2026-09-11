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
  // The Hebrew model is NOT duplicated here. Flutter serves the app's asset
  // bundle under assets/, so assets/tessdata/heb.traineddata - the same file
  // the desktop FFI half unpacks and the mobile plugin reads - is reachable at
  // this URL. One model file for all six platforms, and no second copy to
  // drift out of step with the first.
  var LANG_PATH = 'assets/assets/tessdata';
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
    starting = Tesseract.createWorker('heb', 1, {
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
  function recognise(src) {
    return start().then(function (w) {
      // psm 6 - "assume a single uniform block of text". A nutrition panel is
      // one block; the default (3, full auto page segmentation) hunts for
      // columns that are not there and splits rows.
      //
      // preserve_interword_spaces is deliberately NOT set. The documentation
      // reads as though 1 is the safer choice, and for Latin it is - but on
      // RTL Hebrew it *removes* spaces rather than preserving them:
      // "53.8 גרם" comes back as "53.8גרם" and "משומשום מלא" as
      // "משומשוםמלא". Measured on both engines, same result; see
      // design/m6_platform_research.md.
      return w.setParameters({ tessedit_pageseg_mode: '6' })
        .then(function () { return w.recognize(src); });
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
