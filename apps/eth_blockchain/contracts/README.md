## Contract sources

The contracts are a copy of the [open zeppelin contracts](https://github.com/OpenZeppelin/openzeppelin-solidity/tree/master/contracts).
Except `ERC20MintableLocked.sol`, `ERC20EWallet.sol` and `ERC20EWalletMintable.sol`.

## Compiling contracts

The compiled binary of the contracts were generated using the solidity compiler `solc` with a version matching the `pragma` version at the top of the files.

Commands are ran from the current directory (`contracts`)

### EWallet ERC20

This is a standard ERC20 contract with its total supply defined uppon contract creation.

`solc --bin --abi --overwrite --metadata --optimize --optimize-runs=200 --allow-paths . -o ./compiled/ERC20EWallet ./ERC20/ERC20EWallet.sol`

### EWallet Mintable ERC20

This is a mintable ERC20 contract, a supply can be given uppon contract creation and it can be minted later again until `finishMinting` is called on the contract.

`solc --bin --abi --overwrite --metadata --optimize --optimize-runs=200 --allow-paths . -o ./compiled/ERC20EWalletMintable ./ERC20/ERC20EWalletMintable.sol`