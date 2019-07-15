pragma solidity ^0.5.0;

import "../token/ERC20/ERC20Burnable.sol";

contract ERC20BurnableMock is ERC20Burnable {
    constructor (address initialAccount, uint256 initialBalance) public {
        _mint(initialAccount, initialBalance);
    }
}
