## Compiling contracts

The compiled binary of the contracts were generated using the solidity compiler `solc` with a version matching the `pragma` version at the top of the files.

Commands are ran from the current directory (`contracts`)

### EWallet ERC20

`solc --bin --abi --overwrite --metadata --optimize --optimize-runs=200 --allow-paths . -o ./compiled ./ERC20/ewallet_erc20.sol`