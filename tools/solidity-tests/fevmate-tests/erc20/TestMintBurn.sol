// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../libraries/Test.sol";
import "../../libraries/ErrLib.sol";
import "../../libraries/deployable/Dummy.sol";

import "../../fevmate-mocks/MockERC20.sol";
import "../../fevmate-mocks/MockTokenHolder.sol";

import "fevmate/contracts/utils/FilAddress.sol";

contract TestMintBurn {

    using Test for *;
    using FilAddress for *;

    address creator = msg.sender;

    MockERC20 token;

    constructor() payable { }

    function run() public returns (string[] memory results) {
        return Test.getRunner()
            .setup(this.test__Setup)
            .addM(this.test__MintBurn.named("test__MintBurn"))
            .addM(this.test__MintBurn_Normalize.named("test__MintBurn_Normalize"))
            .addM(this.test__Printer.named("test__Printer"))
            .run();
    }

    // Run before each test:
    // - deploy fresh token contract in this.token
    function test__Setup() external {
        token = new MockERC20("MockCoin", "MOCK", 18);

        // Test properties of deployment
        Test.expect("name should be correct").eq(hash("MockCoin"), hash(token.name()));
        Test.expect("symbol should be correct").eq(hash("MOCK"), hash(token.symbol()));
        Test.expect("decimals should be correct").eq(18, token.decimals());
        Test.expect("totalSupply should be nonzero").neq(0, token.totalSupply());
        Test.expect("deployer should have entire totalSupply as balance").eq(token.totalSupply(), token.balanceOf(address(this)));
    }

    // mint/burn basics
    function test__MintBurn() external {
        test__MintBurnHelper(address(this));
        test__MintBurnHelper(address(0));

        // Test with new eth address
        address dummy = DummyLib.newDummy();
        test__MintBurnHelper(dummy);
    }

    // mint/burn normalization
    function test__MintBurn_Normalize() external {
        // Get Eth and ID address variants for token holder
        MockTokenHolder holderEth = new MockTokenHolder();
        MockTokenHolder holderId = MockTokenHolder(toIDAddress(address(holderEth)));

        Test.expect("really im printing").eq(address(holderEth), address(holderId));
        // Test.print("eth: ").value(address(holderEth));
        // Test.print("id: ").value(address(holderId));
    }

    // perform basic mint/burn operations for _recipient and
    // assert expected output
    function test__MintBurnHelper(address _recipient) internal {
        uint initSupply = token.totalSupply();
        uint initBalance = token.balanceOf(_recipient);

        uint MINT_AMOUNT = 100;
        uint BURN_AMOUNT = 50;

        // Empty mint should not change totalSupply/balanceOf
        token.mint(_recipient, 0);
        Test.expect("supply should be unchanged")
            .eq(initSupply, token.totalSupply());
        Test.expect("balance should be unchanged")
            .eq(initBalance, token.balanceOf(_recipient));

        // Empty burn should not change totalSupply/balanceOf
        token.burn(_recipient, 0);
        Test.expect("supply should be unchanged")
            .eq(initSupply, token.totalSupply());
        Test.expect("balance should be unchanged")
            .eq(initBalance, token.balanceOf(_recipient));

        // Check that minting increases totalSupply and balanceOf
        token.mint(_recipient, MINT_AMOUNT);
        uint newSupply = token.totalSupply();
        uint newBalance = token.balanceOf(_recipient);
        Test.expect("supply should have increased by mint amount")
            .eq(initSupply + MINT_AMOUNT, newSupply);
        Test.expect("balance should have increased by the same")
            .eq(initBalance + MINT_AMOUNT, newBalance);
        
        // Check that minting decreases totalSupply and balanceOf
        token.burn(_recipient, BURN_AMOUNT);
        uint finalSupply = token.totalSupply();
        uint finalBalance = token.balanceOf(_recipient);
        Test.expect("supply should have decreased by burn amount")
            .eq(newSupply - BURN_AMOUNT, finalSupply);
        Test.expect("balance should have decreased by the same")
            .eq(newBalance - BURN_AMOUNT, finalBalance);

        // Make sure we can't burn more than we have
        try token.burn(_recipient, 1 + token.balanceOf(_recipient)) {
            Test.fail("expected error when burn > balance!");
        } catch Panic(uint err) {
            Test.expect("burning more than we have should result in underflow error")
                .eq(err, Test.ARITHMETIC_OVERFLOW_PANIC);
        } catch {
            Test.fail("unexpected error when burn > balance!");
        }

        // Make sure we can burn everything we have
        try token.burn(_recipient, finalBalance) {
            Test.expect("supply should have decreased by balance")
                .eq(finalSupply - finalBalance, token.totalSupply());
            Test.expect("recipient should have zero balance")
                .iszero(token.balanceOf(_recipient));
        } catch {
            Test.fail("unexpected failure when burning entire balance");
        }
    }

    function toIDAddress(address _a) internal view returns (address) {
        (bool success, uint64 id) = _a.getActorID();
        Test.expect("should have retrieved actor id")
            .success(success);
        
        return id.toIDAddress();
    }

    // Dummy function that will fail a test on purpose so we can print things
    function test__Printer() external {
        uint size;
        assembly { size := codesize() }
        Test.print("codesize: ").value(size);
    }

    function hash(string memory _s) internal pure returns (bytes32) {
        return keccak256(bytes(_s));
    }
}