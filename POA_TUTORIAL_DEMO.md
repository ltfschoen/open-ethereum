### Run Parity Ethereum Node

Reference: https://wiki.parity.io/Demo-PoA-tutorial.html

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
