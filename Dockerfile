FROM rustembedded/cross:mips-unknown-linux-gnu

WORKDIR /open-ethereum
COPY . /open-ethereum
RUN printf "Compiling Open Ethereum setup for testing with Big Endian" && \
  dpkg --add-architecture mips-unknown-linux-gnu && \
  apt-get update && \
  apt-get install -y git vim cargo sudo && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y && \
  export PATH=$PATH:/root/.cargo/bin && \
  rustup toolchain install nightly && \
  rustup default nightly && \
  rustup toolchain list && \
  rustup run nightly cargo --version && \
  which rustup && \
  rustup run nightly cargo install cross && \
  uname -a
