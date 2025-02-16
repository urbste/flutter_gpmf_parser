WIP

# flutter_gpmf_parser

A Flutter application for parsing GoPro GPMF data. This library provides functionality to extract and parse GPMF (GoPro Metadata Format) data from GoPro video files.

**Note:** Currently, only Linux and Android platforms have been thoroughly tested. Other platforms may work but are not officially supported yet.

## Prerequisites

- Flutter SDK (>=3.2.3)
- CMake (>=3.10)
- Android SDK and NDK (for Android builds)
- A C compiler (gcc/clang for Linux, NDK toolchain for Android)

## Building and Testing

### Linux Build

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/flutter_gpmf_parser.git
   cd flutter_gpmf_parser
   ```

2. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Build the native library:
   ```bash
   mkdir -p build/linux
   cd build/linux
   cmake ../..
   make
   ```

4. Run the tests:
   ```bash
   flutter test
   ```

### Android Build

1. Make sure you have Android SDK and NDK installed and properly configured in your environment.

2. Set up local.properties in the android folder with your SDK and NDK paths:
   ```properties
   sdk.dir=/path/to/your/Android/sdk
   ndk.dir=/path/to/your/Android/sdk/ndk/version
   ```

3. Build the APK:
   ```bash
   flutter build apk
   ```
   This will automatically build the native library using CMake and package it with the APK.

## Usage

### As a Library

1. Add the dependency to your `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_gpmf_parser:
       git:
         url: https://github.com/yourusername/flutter_gpmf_parser.git
   ```

2. Import and use in your code:
   ```dart
   import 'package:flutter_gpmf_parser/src/gopro_telemetry_extractor.dart';

   // Initialize the extractor
   final extractor = GoProTelemetryExtractor();
   
   // Extract data from a video file
   final telemetryData = await extractor.extractTelemetry('path/to/video.mp4');
   ```

### Sample App

The repository includes a sample application demonstrating the usage of the library:

1. Run the sample app:
   ```bash
   flutter run
   ```

2. Use the file picker to select a GoPro video file
3. The app will extract and display the GPMF metadata

## Platform Support

| Platform | Status      | Notes                                    |
|----------|-------------|------------------------------------------|
| Linux    | ✅ Tested   | Primary development platform             |
| Android  | ✅ Tested   | Tested on various devices                |
| iOS      | ⚠️ Untested | Should work but needs testing            |
| Windows  | ⚠️ Untested | Should work but needs testing            |
| macOS    | ⚠️ Untested | Should work but needs testing            |
| Web      | ❌ N/A      | Native code not supported on web platform |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## License

[Add your license information here]

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
