default: gen lint

gen:
    flutter pub get
    flutter_rust_bridge_codegen \
        -r native/src/api.rs \
        -d lib/bridge_generated.dart \
        -c macos/Runner/bridge_generated.h \
        -e ios/Runner \
        --dart-decl-output lib/bridge_definitions.dart \
        --wasm

lint:
    cd native && cargo fmt
    dart format .

clean:
    flutter clean
    cd native && cargo clean

serve *args='':
    flutter pub run flutter_rust_bridge:serve {{args}}

# vim:expandtab:sw=4:ts=4

# https://docs.flutter.dev/development/platform-integration/desktop
# sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
