# Splash Logo
This directory contains the splash screen logo for the Carlet app.

## Files
- `splash_logo.svg` - Vector source file
- `splash_logo.png` - Raster image used by flutter_native_splash (512x512)

## Generating PNG from SVG
If you need to regenerate the PNG from SVG, you can use:
- Online tools like https://svgtopng.com/
- ImageMagick: `convert -background none splash_logo.svg -resize 512x512 splash_logo.png`
- Inkscape: `inkscape splash_logo.svg --export-type=png --export-width=512 --export-height=512`

## Usage
The splash screen is configured in `pubspec.yaml` under the `flutter_native_splash` section.
To regenerate native splash screens, run:
```bash
flutter pub run flutter_native_splash:create
```
