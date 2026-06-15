# ecomm_demo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Building release artifacts (Android & iOS)

This project includes basic configuration to build Android (APK/AAB) and iOS (IPA) release artifacts.

Android
- Create a file at android/key.properties (NOT committed to git) with the following keys:

  storeFile=/absolute/or/relative/path/to/keystore.jks
  storePassword=your_keystore_password
  keyAlias=your_key_alias
  keyPassword=your_key_password

- Build a release AAB: `flutter build appbundle --release`
- Build a release APK: `flutter build apk --release`

iOS
- Open ios/Runner.xcworkspace in Xcode, set a valid Team for code signing and ensure the PRODUCT_BUNDLE_IDENTIFIER in Xcode project settings is unique.
- Build an archive in Xcode (Product > Archive) and export an IPA using your distribution provisioning profile, or use `flutter build ipa` (requires Xcode command line tools and an Apple developer account).

If you need, I can add scripts or automate parts of this process.
