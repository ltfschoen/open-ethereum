#!/usr/bin/env bash

# Parity Ethereum Dependencies
#
# References:
# - https://github.com/paritytech/parity-ethereum
# - https://wiki.parity.io/Setup

COLOR_WHITE=$(tput setaf 7);
COLOR_MAGENTA=$(tput setaf 5);
FONT_BOLD=$(tput bold);
FONT_NORMAL=$(tput sgr0);

prompt_install () {
  while true; do
    echo
    read -p "Proceed with $1 (Y/N)? > " yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Try again. Please answer yes or no.";;
    esac
  done
}

echo
echo -e "$COLOR_WHITE $FONT_BOLD Parity Ethereum Dependencies Setup...$FONT_NORMAL";
echo
echo -e "  Installing Rust...";
echo
curl https://sh.rustup.rs -sSf | sh -s -- -y;
rustup update nightly;
rustup update stable;
echo
echo -e "  Switching to Rust Nightly...";
rustup default nightly;
cargo install --git https://github.com/alexcrichton/wasm-gc --force;
cargo install --git https://github.com/pepyakin/wasm-export-table.git --force;

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo
  echo -e "  Mac OS Detected...";

  APP="Homebrew"
  echo
  echo -e "$COLOR_MAGENTA $FONT_BOLD Searching for $APP...$COLOR_WHITE $FONT_NORMAL";
  if brew 2>&1 | grep Example; then
    echo -e "  Skipping, $APP already installed";
  else
    if prompt_install $APP; then
      echo -e "  Installing $APP...";
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)";
      export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"
      brew doctor
      brew update
    fi
  fi

  APP="Git"
  echo
  echo -e "$COLOR_MAGENTA $FONT_BOLD Searching for $APP...$COLOR_WHITE $FONT_NORMAL";
  if git 2>&1 | grep usage; then
    echo -e "  Skipping, $APP already installed";
  else
    if prompt_install $APP; then
      echo -e "  Installing $APP latest version...";
      brew install git; brew upgrade git;
      git config --global color.ui auto;
      echo -e "  Please enter your username for $APP Config:";
      read -p "    Username > " uservar
      echo -e "  Please enter your email for $APP Config:";
      read -p "    Email >" emailvar
      git config --global user.name "$uservar";
      git config --global user.email "$emailvar";
      echo
      echo -e "  $APP Config updated with your credentials";
    fi
  fi

  echo
  echo -e "  Installing CMake, Clang, pkg-config, OpenSSL, and Git for Mac OS...";
  brew install openssl; brew upgrade openssl;
  brew install cmake; brew upgrade cmake;
  brew install pkg-config; brew upgrade pkg-config;
  brew install llvm; brew upgrade llvm;
  brew install clang; brew upgrade clang;
else
  prompt_install "Linux OS dependencies installation"
  echo -e "  Installing CMake, pkg-config, Libssl, Git, GNU Make Utility (`make`), C (`gcc`) and C++ (`g++`) compiler for Linux OS...";
  sudo apt update;
  sudo apt upgrade;
  sudo apt install build-essential;
  sudo apt install -y cmake pkg-config libssl-dev git libudev-dev file
  echo -e "  Verify installation...";
  whereis gcc g++ make;
  gcc --version;
  make -v;
fi
