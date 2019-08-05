pragma solidity ^0.5.0;

import "./ERC20Mintable.sol";

/**
 * @dev Extension of `ERC20Mintable` that adds the ability to lock the minting.
 */
contract ERC20MintableLocked is ERC20Mintable {

    event MintFinished();

    bool public mintingFinished = false;

    /**
     * @dev See `ERC20._mint`.
     *
     * Requirements:
     *
     * - the caller must have the `MinterRole`.
     */
    function mint(address account, uint256 amount) public canMint returns (bool) {
        return super.mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * @return True if the operation was successful.
     *
     * Requirements:
     *
     * - the caller must have the `MinterRole`.
     */
    function finishMinting() public onlyMinter returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /** Make sure we are not done yet. */
    modifier canMint() {
        if(mintingFinished) revert("Minting is finished");
        _;
    }
}
