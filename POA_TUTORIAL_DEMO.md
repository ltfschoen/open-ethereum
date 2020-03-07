### Run Parity Ethereum Node with Cross Compilation on "Big Endian" Hardware

#### Credit

Thanks to the following who helped me with this:
* Sergei Shulepov
* Niklas Adolfsson (niklasad1)
* David Plum (dvdplm)

#### Goal

The goal is to port the Open Ethereum client v2.8 to "big endian" architecture (like IBM Z mainframes), since issues (e.g. with serialisation and crypto) are being encountered because Open Ethereum implicitly assumes "little endian" architecture 

#### Support for Big Endian Hardware in Open Ethereum

We cannot test it on macOS, since modern versions of macOS support only Intel architectures, namely only x86_64, which is only little endian (LE), where endianess is a property of a hardware architecture not of an operating system. 

Macintosh did have PowerPC big endian (BE) hardware in the past, however better targets might be ARM based, since some of them can be run in both BE and LE mode, at least theoretically.

Credit: Sergei Shulepov.

#### Obtaining Access to Test on Big Endian Hardware

Initial thoughts were to try to access z/OS and Linux on IBM Z IBM Z mainframe, but https://www.ibm.com/it-infrastructure/z/education is only available to some recognized educational institutions, not open source.

Then an attempt was made to register with VMware to obtain access to either a Stromasys Virtual SPARC Emulator or Virual Alpha Emulter for VMware Cloud which allows deploying emulators of this legacy BE hardware on AWS, as mentioned here https://aws.amazon.com/blogs/apn/re-hosting-sparc-alpha-or-other-legacy-systems-to-aws-with-stromasys/, however VMware registration does not work.

The most feasible solution is to use "cross" (https://github.com/rust-embedded/cross), which allows for cross-compilation to test Rust crates on different architectures like BE, as mentioned in this Open Ethereum relevant issue https://github.com/paritytech/parity-common/issues/27.

To build for BE on MIPS, your target should be `mips-unknown-linux-gnu`

#### Setup Cross Compilation using Cross

* Go to https://github.com/rust-embedded/cross#dependencies
* Configure Cross.toml and Dockerfile in project's root folder
* Run:

```
docker-compose up --build -d && docker exec -it --privileged=true $(docker ps -q) bash
```

* Then setup your environment for Cross with:

```
export PATH=$PATH:/root/.cargo/bin
source $HOME/.cargo/env
```

If it worked successfully then when you run `rustc --print sysroot` it should output: `/root/.rustup/toolchains/stable-x86_64-unknown-linux-gnu` (see https://github.com/rust-embedded/cross/issues/384)

* Then start Docker within the Docker container with:
```
sudo service docker start
```

* Then inside the Docker container shell prompt, build Open Ethereum on MIPS (Big Endian) using Cross:

```
RUST_BACKTRACE=1 QEMU_STRACE=1 /root/.cargo/bin/cross run --target mips-unknown-linux-gnu --release --features final
```

> **ISSUE** The above command currently results in the following error that has been reported to get help here https://github.com/rust-embedded/cross/issues/385

Note: The last command is the equivalent of `cargo build --release --features final` but using `cross` binary instead of `cargo`.

#### Relevant Open Ethereum Issues

A good first step to provide BE support to Open Ethereum would be this "ethash" issue, since "ethash" doesn't work for BE.

https://github.com/paritytech/parity-common/issues/27

Credit: Niklas Adolfsson

There are other issues across the codebases that mention MIPS.

#### Setup Open Ethereum Testnet

* Install Open Ethereum dependencies
  ```
  bash ./scripts/dependencies_mac.sh
  ```

* Install [Open Ethereum](https://github.com/OpenEthereum/parity-ethereum)
  * Build from source
    * Clone latest
      ```
      mkdir -p ~/code/OpenEthereum && cd ~/code/OpenEthereum;
      git clone https://github.com/OpenEthereum/open-ethereum;
      cd open-ethereum;
      ```
    * Build
      * Stable
        * Clean stable. Build in release mode to generate executable in ./target/release subdirectory
          ```
          rustup default stable;
          git checkout stable;
          cargo clean;
          cargo build --release --features final
          ```
      * Nightly - [IGNORE as use 'stable' until issue #10013 resolved](https://github.com/OpenEthereum/open-ethereum/issues/10013#issuecomment-444505679)
        * Clean nightly. Build in release mode to generate executable in ./target/release subdirectory
          ```
          rustup default nightly;
          git checkout master;
          cargo clean;
          cargo build --release --features final
          ```
    * Generate Initial Account to Open Ethereum Authority #1
      * Generate account and enter the password that is in node.pwds (i.e. `node0`)
        ```
        ./target/release/parity account new --chain demo-spec.json --keys-path "/Users/ls/Library/Application Support/io.parity.ethereum/0/keys"
        ```
      * Copy the account address that is generated, and paste it into the node0.toml file (e.g. under key `[account]` with value `unlock = ["0x686c3e9ae7e697fdf943909157119b53ca8bc7da"]`, and also under key `[mining]` and value `engine_signer`)
    * Run Open Ethereum Authority #1
      ```
      ./target/release/parity --config node0.toml
      ```
      * Note that Database (DB) is stored at: ~/Library/Application\ Support/io.parity.ethereum/
      * Generate .toml config with https://paritytech.github.io/parity-config-generator
    * Run the following to add the Consensus Signer and User Accounts to the chain, and return each account address respectively.
      * Engine signer account
        ```
        curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["node0", "node0"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8540
        ```
      * User account
        ```
        curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["user", "user"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8540
        ```
    * Add Consensus Signer and User Account addresses to the node0.toml
      * Replace `engine_signer` with the returned value `0x00bd138abd70e2f00903268f3db08f2d25677c9e`
      * Replace `unlock` with the returned value `0x004ec07d2329997267ec62b4166639513386f32e`
    * Restart Open Ethereum Authority #1
      ```
      ./target/release/parity --config node0.toml
      ```

    * Generate Initial Account to Open Ethereum Authority #2
      * Generate account and enter the password that is in node.pwds (i.e. `node1`)
        ```
./target/release/parity account new --chain demo-spec.json --keys-path "/Users/ls/Library/Application Support/io.parity.ethereum/1/keys"
        ```
      * Copy the account address that is generated, and paste it into the node0.toml file (e.g. under key `[account]` with value `unlock = ["0x84a558fb2dece2cdbe23920a69c84040fddf0cb3"]`, and also under key `[mining]` and value `engine_signer`)
    * Run Open Ethereum Authority #2 (separate terminal)
      ```
      ./target/release/parity --config node1.toml
      ```
    * Generate Authority #1 (using JSON-RPC with chain running)
      * Generate Authority #1
        ```
        curl --data '{"jsonrpc":"2.0","method":"parity_newAccountFromPhrase","params":["node1", "node1"],"id":0}' -H "Content-Type: application/json" -X POST localhost:8541
        ```
       * Record generated address:
        * 0x00aa39d30f0d20ff03a22ccfc30b7efbfca597c2
    * Add Consensus Signer and User Account addresses to the node0.toml
      * Replace `engine_signer` with the returned value `0x00aa39d30f0d20ff03a22ccfc30b7efbfca597c2`
    * Restart Open Ethereum Authority #1
      ```
      ./target/release/parity --config node0.toml
      ```

### References

* https://wiki.parity.io/Demo-PoA-tutorial.html
* https://stackoverflow.com/questions/31938282/is-there-any-bigendian-hardware-out-there
* https://en.wikipedia.org/wiki/Comparison_of_platform_virtualization_software
