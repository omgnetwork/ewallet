pragma solidity ^0.5.0;

import "src/token/ERC20/ERC20.sol";
import "src/token/ERC20/ERC20Detailed.sol";

contract EWalletERC20 is ERC20, ERC20Detailed {
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 initialSupply) ERC20Detailed(name, symbol, decimals) public {
        _mint(msg.sender, initialSupply);
    }
}