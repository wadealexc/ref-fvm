// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "fevmate/contracts/token/ERC20.sol";

contract MockERC20 is ERC20 {

    uint constant SUPPLY = 1_000_000;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        _mint(msg.sender, SUPPLY);
    }

    function mint(address _recipient, uint _amount) public {
        _mint(_recipient, _amount);
    }

    function burn(address _from, uint _amount) public {
        _burn(_from, _amount);
    }
}