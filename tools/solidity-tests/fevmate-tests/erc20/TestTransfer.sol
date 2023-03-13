// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../../libraries/Test.sol";
import "../../../libraries/ErrLib.sol";
import "../../../libraries/deployable/Dummy.sol";

import "../../../fevmate-mocks/MockERC20.sol";

contract TestTransfer {

    // using FilUtils for *;
    using Test for *;

    address creator = msg.sender;

    MockERC20 token;

    constructor() payable { }

    function run() public returns (string[] memory results) {
        return Test.getRunner()
            .setup(this.test__Setup)
            .addM(this.test__Transfer.named("test__Transfer"))
            .addM(this.test__Approve.named("test__Approve"))
            .addM(this.test__TransferFrom.named("test__TransferFrom"))
            .addM(this.test__Printer.named("test__Printer"))
            .run();
    }

    // Run before each test:
    // - deploy fresh token contract in this.token
    function test__Setup() external {
        token = new MockERC20("MockCoin", "MOCK", 18);
        // Test.todo();
    }

    // transfer basics
    function test__Transfer() external {
        uint preBalance = token.balanceOf(address(this));
        Test.expect("should have nonzero balance").neq(preBalance, 0);

        bool result = token.transfer(creator, preBalance);
        Test.expect("token transfer should succeed").success(result);

        uint postBalance = token.balanceOf(address(this));
        Test.expect("we should now have zero balance").iszero(postBalance);

        uint recipientBalance = token.balanceOf(creator);
        Test.expect("should have transferred all tokens to creator").eq(preBalance, recipientBalance);
    }

    // approve basics
    function test__Approve() external {
        Test.todo();
    }

    // transferFrom basics
    function test__TransferFrom() external {
        Test.todo();
    }

    // Dummy function that will fail a test on purpose so we can print things
    function test__Printer() external {
        Test.print("creator address: ").value(creator);
    }

    function hash(string memory _s) internal pure returns (bytes32) {
        return keccak256(bytes(_s));
    }
}