default: setup

setup:
    flutter pub get
    cd flows && flutter pub get
    cd rust_builder && flutter pub get

gen: setup
    cargo install flutter_rust_bridge_codegen@2.1.0
    flutter_rust_bridge_codegen generate \
        --rust-root=rust \
        --rust-input crate::api \
        --dart-output lib/gen \
        --c-output macos/Runner/bridge_generated.h

l10n:
    flutter gen-l10n

lint:
    cd rust && cargo fmt
    dart format .

clean:
    flutter clean
    cd rust && cargo clean

test:
    cd flows && dart run --enable-asserts example/sync.dart --test ../resources/flows

sync:
    cd flows && dart run --enable-asserts example/sync.dart --sync ../resources/flows

serve *args='':
    flutter pub run flutter_rust_bridge:serve {{args}}

# vim:expandtab:sw=4:ts=4

# https://docs.flutter.dev/development/platform-integration/desktop
# sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
