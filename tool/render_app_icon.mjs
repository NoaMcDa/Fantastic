// Rasterises assets/icons/*.svg into the PNG sources flutter_launcher_icons
// consumes. Chromium is the renderer because this machine has no
// rsvg-convert, Inkscape, ImageMagick, Pillow or cairosvg — and Chromium is
// pre-installed for the Playwright-based tooling.
//
// Run from the repo root:  node tool/render_app_icon.mjs
import { chromium } from '/opt/node22/lib/node_modules/playwright/index.mjs';
import { readFileSync, writeFileSync } from 'node:fs';

const targets = [
  { svg: 'assets/icons/app_icon.svg', out: 'assets/icons/app_icon.png', size: 1024, transparent: false },
  { svg: 'assets/icons/app_icon_foreground.svg', out: 'assets/icons/app_icon_foreground.png', size: 1024, transparent: true },
  // Linux. flutter_launcher_icons does not cover this target at all, so the
  // hicolor sizes a desktop launcher looks for are rendered here instead.
  { svg: 'assets/icons/app_icon.svg', out: 'linux/packaging/fantastic-512.png', size: 512, transparent: false },
  { svg: 'assets/icons/app_icon.svg', out: 'linux/packaging/fantastic-256.png', size: 256, transparent: false },
  { svg: 'assets/icons/app_icon.svg', out: 'linux/packaging/fantastic-128.png', size: 128, transparent: false },
  { svg: 'assets/icons/app_icon.svg', out: 'linux/packaging/fantastic-64.png', size: 64, transparent: false },
];

const browser = await chromium.launch();
for (const t of targets) {
  const svg = readFileSync(t.svg, 'utf8');
  const page = await browser.newPage({ viewport: { width: t.size, height: t.size } });
  await page.setContent(
    `<!doctype html><meta charset="utf-8">
     <body style="margin:0;width:${t.size}px;height:${t.size}px;overflow:hidden">
       <div id="m" style="width:${t.size}px;height:${t.size}px">${svg}</div>
     </body>`,
  );
  // The SVG declares 512; force it to the target edge so the raster is exact.
  await page.evaluate((size) => {
    const el = document.querySelector('svg');
    el.setAttribute('width', String(size));
    el.setAttribute('height', String(size));
  }, t.size);
  const buf = await page.locator('#m').screenshot({ omitBackground: t.transparent });
  writeFileSync(t.out, buf);
  await page.close();
  console.log(`${t.out} — ${t.size}x${t.size}${t.transparent ? ' (alpha)' : ''}`);
}
await browser.close();
