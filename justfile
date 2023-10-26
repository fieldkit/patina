default: setup

setup:
    flutter pub get
    cd calibration && flutter pub get
    cd flows && flutter pub get

gen: setup
    cargo install flutter_rust_bridge_codegen@1.82.1
    flutter_rust_bridge_codegen \
        -r native/src/api.rs \
        -d lib/gen/bridge_generated.dart \
        --dart-decl-output lib/gen/bridge_definitions.dart \
        -c macos/Runner/bridge_generated.h \
        -e ios/Runner \
        --wasm --verbose

l10n:
    flutter gen-l10n

lint:
    cd native && cargo fmt
    dart format .

clean:
    flutter clean
    cd native && cargo clean

test:
    cd flows && dart run --enable-asserts example/sync.dart --test

sync:
    cd flows && dart run --enable-asserts example/sync.dart --sync

serve *args='':
    flutter pub run flutter_rust_bridge:serve {{args}}

# vim:expandtab:sw=4:ts=4

# https://docs.flutter.dev/development/platform-integration/desktop
# sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
