# 📱 FieldKit Mobile App

Dive into the development of FieldKit using Flutter and Rust. This guide provides steps to set up your environment, work with RustFK and troubleshoot common iOS issues.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Setup and Dependencies](#setup-and-dependencies)
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

> **Tip**: If you modify the version in `pubspec.yaml`, remember to execute `flutter clean`.

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

## 🏃 Run the Code 

Run the Flutter application with:

```bash
flutter run
```


## 🧪 Running the Tests

Test the Flutter application with:

```bash
flutter test
```