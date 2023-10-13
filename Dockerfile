FROM ghcr.io/cirruslabs/flutter:3.13.0

ENV CARGO_HOME=$HOME/.cargo
ENV PATH=$PATH:$CARGO_HOME/.bin

RUN apt-get update && apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev && rm -rf /var/lib/apt/lists/*

RUN yes | sdkmanager --install 'ndk;25.2.9519653'
RUN yes | sdkmanager --install "build-tools;30.0.3"
RUN yes | sdkmanager --install "platforms;android-33"
RUN yes | sdkmanager --install "platform-tools"

RUN mkdir -p ~/.gradle && echo "ANDROID_NDK=$ANDROID_SDK_ROOT/ndk" >> ~/.gradle/gradle.properties

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh
RUN sh rustup.sh -y
RUN PATH="$CARGO_HOME/bin:$PATH" rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
RUN PATH="$CARGO_HOME/bin:$PATH" cargo install cargo-ndk

RUN flutter doctor --android-licenses