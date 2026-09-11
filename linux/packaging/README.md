# Linux packaging assets

`flutter build linux` produces a bundle and nothing else — no icon, no
desktop entry. Flutter's Linux template ships neither, which is why nothing
here existed until #92: a packaged build showed a generic placeholder in
every launcher, and `flutter build linux` never complained because it does
not look.

These files are inputs for whoever builds the package (a `.deb`, a Flatpak,
an AppImage). They are not consumed by `flutter build linux`.

| File | Installs as |
|---|---|
| `com.fantastic.fantastic.desktop` | `/usr/share/applications/com.fantastic.fantastic.desktop` |
| `fantastic-<n>.png` | `/usr/share/icons/hicolor/<n>x<n>/apps/com.fantastic.fantastic.png` |

The `Icon=` key is the application ID rather than a path, so the icon is
resolved through the hicolor theme at whatever size the launcher wants —
which is the reason four sizes are shipped instead of one.

`Exec=` and `StartupWMClass=` are `fantastic`, matching `BINARY_NAME` in
`linux/CMakeLists.txt`; `Icon=` and the installed filename are
`com.fantastic.fantastic`, matching `APPLICATION_ID` there. Those two are
different strings in that file and are different here for the same reason.

Regenerate the PNGs with `node tool/render_app_icon.mjs`.
