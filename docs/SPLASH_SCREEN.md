# Splash Screen Implementation

This document describes the splash screen implementation for the Carlet app using `flutter_native_splash`.

## Overview

The splash screen displays while the Flutter engine initializes. It provides a branded experience on both iOS and Android platforms with full dark mode support.

## Configuration

The splash screen is configured in `pubspec.yaml` under the `flutter_native_splash` section:

```yaml
flutter_native_splash:
  color: "#2196F3"              # Light mode background (Material Blue)
  color_dark: "#1565C0"          # Dark mode background (Darker Blue)
  android: true
  android_12:
    image: assets/splash_logo.png
    color: "#2196F3"
    color_dark: "#1565C0"
    icon_background_color: "#2196F3"
    icon_background_color_dark: "#1565C0"
  ios: true
  ios_content_mode: center
  fullscreen: true
  info_plist_files:
    - 'ios/Runner/Info.plist'
```

## Features

✅ **Platform Support**: iOS and Android
✅ **Dark Mode**: Automatic switching based on system settings
  - Light mode: `#2196F3` (Material Blue)
  - Dark mode: `#1565C0` (Darker Blue)
✅ **Android 12+**: Uses the new splash screen API
✅ **Full Screen**: Covers status bar for immersive experience
✅ **Branded Logo**: Custom car icon with notification badge

## Assets

- **Source Logo**: `assets/splash_logo.svg` - Vector source file
- **Splash Image**: `assets/splash_logo.png` - 512x512 PNG used by the native splash screen
- **Generation Script**: `tools/scripts/create_splash_logo.py` - Python script to regenerate the logo

## Regenerating the Splash Screen

If you modify the configuration or logo, regenerate the native splash screens:

```bash
# Regenerate the logo (if needed)
python3 tools/scripts/create_splash_logo.py

# Regenerate native splash screens
dart run flutter_native_splash:create
```

## Generated Files

### Android
- `android/app/src/main/res/drawable*/android12splash.png` - Splash images for different densities
- `android/app/src/main/res/drawable*/launch_background.xml` - Launch backgrounds
- `android/app/src/main/res/values*/styles.xml` - Theme configurations for light/dark mode

### iOS
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/` - Launch images
- `ios/Runner/Base.lproj/LaunchScreen.storyboard` - Launch screen storyboard
- `ios/Runner/Info.plist` - Updated with splash screen settings

## Color Scheme

The splash screen uses Carlet's primary brand colors:

| Mode | Background Color | Hex Code |
|------|------------------|----------|
| Light | Material Blue | `#2196F3` |
| Dark | Dark Blue | `#1565C0` |

## Logo Design

The splash logo features:
- Simple car silhouette in blue
- Orange notification badge with exclamation mark
- "Carlet" text below the icon
- Clean, minimal design for quick recognition

## Testing

Test the splash screen on physical devices or emulators:

```bash
# Run on Android
flutter run

# Run on iOS
flutter run -d iphone

# Build for release to see actual splash screen timing
flutter build apk
flutter build ios
```

## Notes

- The splash screen displays during native app initialization before Flutter starts
- On Android 12+, the splash screen uses the new splash screen API with icon background
- On iOS, the splash screen uses LaunchScreen.storyboard
- Full screen mode ensures the splash covers the entire screen including status bar
- Dark mode switching is automatic based on system settings

## Customization

To customize the splash screen:

1. **Change Colors**: Update `color` and `color_dark` in `pubspec.yaml`
2. **Change Logo**: Replace `assets/splash_logo.png` or regenerate using the Python script
3. **Adjust Behavior**: Modify configuration options in `pubspec.yaml`
4. **Regenerate**: Run `dart run flutter_native_splash:create`

## Troubleshooting

**Splash screen not showing:**
- Clean and rebuild: `flutter clean && flutter pub get`
- Regenerate splash screens: `dart run flutter_native_splash:create`
- Check that `flutter_native_splash` is in `dev_dependencies`

**Wrong colors:**
- Verify hex colors in `pubspec.yaml` include the `#` prefix
- Regenerate after changing colors

**Image not appearing:**
- Ensure `assets/splash_logo.png` exists and is 512x512 pixels
- Check file path in `pubspec.yaml` configuration
- Regenerate splash screens after updating the image

## Package Information

- **Package**: flutter_native_splash ^2.4.3
- **Repository**: https://pub.dev/packages/flutter_native_splash
- **Documentation**: https://pub.dev/packages/flutter_native_splash#documentation
