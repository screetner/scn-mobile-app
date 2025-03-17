# Flutter Project Documentation

## How to Run on Development

1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Create a `.env` file in the root directory following the structure in `.env.example`
4. Launch an emulator or connect a physical device:
   ```bash
   # List available emulators
   flutter emulators

   # Start a specific emulator
   flutter emulators --launch <emulator_id>
   
   # Or use Android Studio's AVD Manager or XCode's simulator
   ```
5. Run the app in development mode:
   ```bash
   flutter run
   ```

## How to Build APK

1. To build a debug APK:
   ```bash
   flutter build apk --debug
   ```

2. To build a release APK:
   ```bash
   flutter build apk --release
   ```

3. To build a profile APK:
   ```bash
   flutter build apk --profile
   ```

4. The generated APK will be available at:
   ```
   build/app/outputs/flutter-apk/app-[build-type].apk
   ```

## Environment Configuration

If you need to pass environment variables:
```bash
flutter run --dart-define=API_URL=your_api_url
```

Multiple variables can be combined:
```bash
flutter run --dart-define=API_URL=your_api_url --dart-define=TUSD_SERVER_URL=your_server_url
```

## Build Requirements

- Flutter SDK
- For Android: Android SDK, JDK
- At least one emulator configured or physical device for testing

[//]: # (- For iOS: Xcode, CocoaPods)