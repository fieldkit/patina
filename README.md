# 📱 FieldKit Mobile App

Stay ahead in the field with FieldKit mobile app. Here's everything you need to get started to build the fieldkit app.

This version is for contributors or developers, to download the [Android app](https://play.google.com/store/apps/details?id=com.fieldkit) or the [iOS app](https://apps.apple.com/us/app/fieldkit-org/id1463631293).

![screenshot of app](README_image.png)

## Table of Contents
- [Prerequisites](#prerequisites)
- [Setup and Dependencies](#setup-and-dependencies)
- [Running the Code](#running-the-code)
- [Running the Tests](#running-the-tests)

## 🛠 Prerequisites

Before you get started, ensure you have the following installed:

- **Flutter SDK**: [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Rust Language**: [Get Rustup](https://rustup.rs/)
- **Rust Targets**: For cross-compiling to your device. [Read More](https://rust-lang.github.io/rustup/cross-compilation.html)

### Android-Specific Dependencies:
- **cargo-ndk**: [Installation Instructions](https://github.com/bbqsrc/cargo-ndk#installing)
- **Android NDK 22**: After installation, set its path using:

```bash
echo "ANDROID_NDK=path/to/ndk" >> ~/.gradle/gradle.properties
```

## 📦 Setup and Dependencies

### RustFK

1. **Clone the Repository**:
```bash
git clone https://github.com/fieldkit/rustfk
```

2. **Integrate your Rust code**: Edit `api.rs` as needed. Afterwards, get the "just" task runner:
```bash
cargo install just
```

3. **Generate Bridge Files**:
   First, ensure the codegen tool's version matches `flutter_rust_bridge` in `pubspec.yaml` and `flutter_rust_bridge` & `flutter_rust_bridge_macros` inside `native/Cargo.toml`.

```bash
cargo install -f --version 1.82.1 flutter_rust_bridge_codegen
```

> 🔧 **Tip**: @henever you adjust the version in `pubspec.yaml`, ensure to run `flutter clean`.

### 🍏 iOS Troubleshooting

Facing build issues with iOS? Try the following:

- **Licensing issues**:
```bash
xcodebuild -license
```

- **Missing iOS platforms**:
```bash
xcodebuild -downloadPlatform iOS
```

- **Installing simulators**:
```bash
xcodebuild -runFirstLaunch
```

OR

```bash
xcodebuild -downloadAllPlatforms
```

## 🏃 Running the Code 

Run the Flutter application with:

```bash
flutter run
```


## 🧪 Running the Tests

Test the Flutter application with:

```bash
flutter test
```