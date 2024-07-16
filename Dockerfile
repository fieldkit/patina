FROM ghcr.io/cirruslabs/flutter:3.22.2 AS base

RUN apt-get update && apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/mozilla/sccache/releases/download/v0.2.15/sccache-v0.2.15-x86_64-unknown-linux-musl.tar.gz \
    && tar xzf sccache-v0.2.15-x86_64-unknown-linux-musl.tar.gz \
    && mv sccache-v0.2.15-x86_64-unknown-linux-musl/sccache /usr/local/bin/sccache \
    && chmod +x /usr/local/bin/sccache

RUN yes | sdkmanager --install 'ndk;25.2.9519653'
RUN yes | sdkmanager --install "build-tools;30.0.3"
RUN yes | sdkmanager --install "platforms;android-33"
RUN yes | sdkmanager --install "platform-tools"

RUN mkdir -p ~/.gradle && echo "ANDROID_NDK=$ANDROID_SDK_ROOT/ndk" >> ~/.gradle/gradle.properties

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh
RUN sh rustup.sh -y

ENV HOME="/root"
ENV PATH="${HOME}/.cargo/bin:$PATH"
ENV SCCACHE_CACHE_SIZE="5G"
ENV SCCACHE_DIR=/cache/sccache
ENV RUSTC_WRAPPER=/usr/local/bin/sccache

RUN rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

RUN cargo install cargo-ndk

# This isn't used right now. Remember the architecture if you try it out.
# RUN cargo install cargo-chef

RUN flutter doctor --android-licenses

FROM base AS prime-sccache
WORKDIR "/temporary-build"
RUN git clone https://gitlab.com/fieldkit/libraries/rustfk.git
COPY . .
# Always remember Android is a different architecture, easy to skim over.
RUN cd rust && cargo ndk -t armeabi-v7a -t arm64-v8a -t x86 -t x86_64 -o ../android/app/src/main/jniLibs build --release && sccache --show-stats
WORKDIR /
RUN rm -rf /temporary-build
