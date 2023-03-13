// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../libraries/Test.sol";
import "../../libraries/ErrLib.sol";
import "../../libraries/deployable/Dummy.sol";

import "../../fevmate-mocks/MockERC20.sol";
import "../../fevmate-mocks/MockEmpty.sol";

import "fevmate/contracts/utils/FilAddress.sol";

contract TestFilAddress {

    // using FilUtils for *;
    using Test for *;
    using FilAddress for *;

    address creator = msg.sender;
    MockERC20 token;

    constructor() payable { }

    function run() public returns (string[] memory results) {
        return Test.getRunner()
            .setup(this.test__Setup)
            .addM(this.test__IsIDAddress.named("test__IsIDAddress"))
            .addM(this.test__Normalize.named("test__Normalize"))
            .addM(this.test__GetEthAddressAndActorID.named("test__GetEthAddressAndActorID"))
            .addM(this.test__Printer.named("test__Printer"))
            .run();
    }

    // Run before each test
    function test__Setup() external {
        token = new MockERC20("MockCoin", "MOCK", 18);
        // Test.todo();
    }

    // various error strings - reduces bytecode size since we reuse these a lot
    string constant EXPECT_NOT_ID_STR = "should not be id address";
    string constant EXPECT_ID_STR = "should be id address";
    string constant EXPECT_GET_ID_STR = "should get actor id";
    string constant EXPECT_GET_ETH_STR = "should get eth address";
    string constant EXPECT_VALID_ID_STR = "id should be at least 100";
    string constant EXPECT_ROUNDTRIP_STR = "should retrieve original address";

    // FilAddress.isIDAddress() -> (bool isID, uint64 id)
    function test__IsIDAddress() external {
        // ADDRESS should never yield an ID address
        (bool isID, ) = address(this).isIDAddress();
        Test.expect(EXPECT_NOT_ID_STR).fail(isID);

        // If we deploy a contract, we shouldn't get an ID address
        address fresh = address(new MockEmpty());
        (isID, ) = fresh.isIDAddress();
        Test.expect(EXPECT_NOT_ID_STR).fail(isID);

        // Zero address
        (isID, ) = address(0).isIDAddress();
        Test.expect(EXPECT_NOT_ID_STR).fail(isID);

        // EVM/FEVM Precompiles
        (isID, ) = address(1).isIDAddress();
        Test.expect(EXPECT_NOT_ID_STR).fail(isID);
        (isID, ) = FilAddress.RESOLVE_ADDRESS.isIDAddress();
        Test.expect(EXPECT_NOT_ID_STR).fail(isID);

        // Zero ID address
        uint id;
        (isID, id) = FilAddress.ZERO_ID_ADDRESS.isIDAddress();
        Test.expect(EXPECT_ID_STR).success(isID);
        Test.expect("should be ID 0").eq(id, 0);

        // MAX ID address
        (isID, id) = FilAddress.MAX_ID_ADDRESS.isIDAddress();
        Test.expect(EXPECT_ID_STR).success(isID);
        Test.expect("should be u64 max").eq(id, type(uint64).max);

        // ID 5
        (isID, id) = FilAddress.toIDAddress(5).isIDAddress();
        Test.expect(EXPECT_ID_STR).success(isID);
        Test.expect("should be id 5").eq(id, 5);

        // MAX ID address plus 1
        address maxPlusOne = address(0xFf0000000000000000000000FFfFFFFfFfFffFfF);
        assembly { maxPlusOne := add(1, maxPlusOne) }
        (isID, ) = maxPlusOne.isIDAddress();
        Test.expect(EXPECT_NOT_ID_STR).fail(isID);
    }

    function test__Normalize() external {
        
    }

    // FilAddress.getEthAddress(u64) -> (bool, address)
    // FilAddress.getActorID(address) -> (bool, u64)
    function test__GetEthAddressAndActorID() external {
        // 1. Already-deployed contract
        // - should have both Eth and ID addresses
        address eth = address(token);
        (bool isID, ) = eth.isIDAddress();
        Test.expect(EXPECT_NOT_ID_STR).fail(isID);
        // Get Actor ID
        (bool success, uint64 id) = eth.getActorID();
        Test.expect(EXPECT_GET_ID_STR).success(success);
        Test.expect(EXPECT_VALID_ID_STR).gte(id, 100);
        // Convert back to Eth address
        address converted;
        (success, converted) = id.getEthAddress();
        Test.expect(EXPECT_GET_ETH_STR).success(success);
        Test.expect(EXPECT_ROUNDTRIP_STR).eq(converted, eth);

        // 2. address(this)
        // - should have both Eth and ID addresses
        eth = address(this);
        (isID, ) = eth.isIDAddress();
        Test.expect(EXPECT_NOT_ID_STR).fail(isID);
        // Get Actor ID
        (success, id) = eth.getActorID();
        Test.expect(EXPECT_GET_ID_STR).success(success);
        Test.expect(EXPECT_VALID_ID_STR).gte(id, 100);
        // Convert back to Eth address
        (success, converted) = id.getEthAddress();
        Test.expect(EXPECT_GET_ETH_STR).success(success);
        Test.expect(EXPECT_ROUNDTRIP_STR).eq(converted, eth);

        // 3. Two new contracts
        // - should have both address types, and second should have idFirst + 1
        address first = address(new MockEmpty());
        address second = address(new MockEmpty());
        (isID, ) = first.isIDAddress();
        Test.expect(EXPECT_NOT_ID_STR).fail(isID);
        (isID, ) = second.isIDAddress();
        Test.expect(EXPECT_NOT_ID_STR).fail(isID);
        // Get Actor IDs
        uint64 idFirst;
        uint64 idSecond;
        (success, idFirst) = first.getActorID();
        Test.expect(EXPECT_GET_ID_STR).success(success);
        Test.expect(EXPECT_VALID_ID_STR).gte(idFirst, 100);
        (success, idSecond) = second.getActorID();
        Test.expect(EXPECT_GET_ID_STR).success(success);
        Test.expect("second actor created should be idFirst + 1").eq(idFirst + 1, idSecond);
        // Convert back to Eth address
        (success, converted) = idFirst.getEthAddress();
        Test.expect(EXPECT_GET_ETH_STR).success(success);
        Test.expect(EXPECT_ROUNDTRIP_STR).eq(converted, first);
        (success, converted) = idSecond.getEthAddress();
        Test.expect(EXPECT_GET_ETH_STR).success(success);
        Test.expect(EXPECT_ROUNDTRIP_STR).eq(converted, second);

        // 4. creator (non-EVM account)
        (isID, id) = creator.isIDAddress();
        Test.expect(EXPECT_ID_STR).success(isID);
        Test.expect(EXPECT_VALID_ID_STR).gte(id, 100);
        // getActorID should return the same address
        uint64 lookupID;
        (success, lookupID) = creator.getActorID();
        Test.expect(EXPECT_GET_ID_STR).success(success);
        Test.expect("ids should be equal").eq(id, lookupID);
        // getEthAddress should fail
        (success, ) = id.getEthAddress();
        Test.expect("should not succeed in retrieving Eth address").fail(success);
    }

    // Dummy function that will fail a test on purpose so we can print things
    function test__Printer() external {
        uint size;
        assembly { size := codesize() }
        Test.print("codesize: ").value(size);
    }
}