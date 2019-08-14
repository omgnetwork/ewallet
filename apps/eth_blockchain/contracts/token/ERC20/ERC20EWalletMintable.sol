pragma solidity ^0.5.0;

import "./ERC20MintableLocked.sol";
import "./ERC20Detailed.sol";

contract ERC20EWalletMintable is ERC20MintableLocked, ERC20Detailed {
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 initialSupply) ERC20Detailed(name, symbol, decimals) public {
        _mint(msg.sender, initialSupply);
    }
}