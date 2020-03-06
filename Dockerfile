FROM rustembedded/cross:mips-unknown-linux-gnu

WORKDIR /open-ethereum
COPY . /open-ethereum
RUN printf "Compiling Open Ethereum setup for testing with Big Endian" && \
  dpkg --add-architecture mips-unknown-linux-gnu && \
  apt-get update && \
  apt-get install -y git vim cargo sudo && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y && \
  echo 'PATH="/root/.cargo/bin:$PATH";' >> ~/.bash_profile && . ~/.bash_profile && \
  . /root/.cargo/env && \
  rustup toolchain install nightly && \
  rustup default nightly && \
  rustup toolchain list && \
  rustup run nightly cargo --version && \
  which rustup && \
  rustup run nightly cargo install cross && \
  uname -a
RUN apt-get update && \
  apt-get install -y gnupg2 && \
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common && \
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic test" && \
  apt-get -y update && apt-get -y upgrade && \
  apt install -y docker-ce docker-compose && \
  docker --version

# sudo service docker start
# sudo service docker restart
# sudo journalctl -fu docker
#
# Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
#
# docker version
# docker info
# journalctl -xe
# ps -ax | grep docker
# cat /lib/systemd/system/docker.service
# /etc/init.d/dbus start
# systemctl start docker
#   Failed to connect to bus: No such file or directory
# systemctl status docker.service
# export PATH=$PATH:/root/.cargo/bin
# source $HOME/.cargo/env
# RUST_BACKTRACE=1 QEMU_STRACE=1 /root/.cargo/bin/cross run --target mips-unknown-linux-gnu --release --features final
