# FieldKit Mobile App

## Getting Started

To begin, ensure that you have a working installation of the following items:
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Rust language](https://rustup.rs/)
- Appropriate [Rust targets](https://rust-lang.github.io/rustup/cross-compilation.html) for cross-compiling to your device
- For Android targets:
    - Install [cargo-ndk](https://github.com/bbqsrc/cargo-ndk#installing)
    - Install Android NDK 22, then put its path in one of the `gradle.properties`, e.g.:

```
echo "ANDROID_NDK=.." >> ~/.gradle/gradle.properties
```

# Rust Dependencies

This project makes use of the task runner "just" to perform common operations,
it can be installed using Rust's cargo command:


### RustFK
Add the following repository to the base of the folder

`git clone https://github.com/fieldkit/rustfk`


Once you have edited `api.rs` to incorporate your own Rust code, the bridge files `bridge_definitions.dart` and `bridge_generated.dart` are generated using the following command:

```
cargo install just
```

The bindings between the Flutter/Dart app and the Rust library may need to be
regenerated, and to do so the codegen tool will need to be installed.

```
cargo install -f --version 1.82.1 flutter_rust_bridge_codegen
```

You'll notice the version is specified directly above, otherwise the latest
version will be installed. This version should match the one specified for
`flutter_rust_bridge` in the `pubspec.yaml` as well as for
`flutter_rust_bridge` and `flutter_rust_bridge_macros` inside
`native/Cargo.toml`. Drift among these versions is a common source of compile
errors. When changing the version in `pubspec.yaml` a `flutter clean` is also
usually necessary.

### iOS

When the iOS build fails, it's usually do to new platforms/versions of things
and depending on the situation discovering which command you can run from the
command line to solve the issue can be quite difficult. I've started collecting
them here:

This is one that it'll at least suggest to you:

```
xcodebuild -license
```

In response to this message:

> iOS 17.0 is not installed. To download and install the platform, open Xcode,
> select Xcode > Settings > Platforms, and click the GET button for the required
> platform.

I used the following:


```
xcodebuild -downloadPlatform iOS
```

I've run the following to install simulators, though I have a feeling if you use the `-downloadPlatform` command that may be better.

```
xcodebuild -runFirstLaunch
```

I've never used this one, and have only used the one above.

```
xcodebuild -downloadAllPlatforms
```
