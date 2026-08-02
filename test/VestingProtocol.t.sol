// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {VestingProtocol} from "../src/VestingProtocol.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock token, само за тестове - минтваме си колкото искаме

contract MockToken is ERC20 {

    constructor() ERC20("Mock Token", "MOCK") {

        _mint(msg.sender, 1_000_000 ether);
    }
}


contract VestingProtocolTest is Test {

    VestingProtocol public vesting;
    MockToken public token;
    address public beneficiary = makeAddr("beneficiary");
    uint256 public constant TOTAL_AMOUNT = 1000 ether;
    uint256 public constant DURATION = 365 days;


    // setUp() се вика преди всеки тест - чисто състояние всеки път
    function setUp() public {

        token = new MockToken();
        // match constructor signature (beneficiary, token, duration, totalAmount)
        vesting = new VestingProtocol(beneficiary, address(token), DURATION, TOTAL_AMOUNT);
        // прехвърляме токените, които ще се vest-ват, в контракта
        token.transfer(address(vesting), TOTAL_AMOUNT);

    }

    // Проверява, че constructor-ът е записал правилно данните
    function test_ConstructorSetsCorrectValues() public view {

        assertEq(vesting.beneficiary(), beneficiary);
        assertEq(vesting.totalAmount(), TOTAL_AMOUNT);
        assertEq(vesting.duration(), DURATION);

    }

    // На половината от периода трябва да е vested точно половината сума

    function test_VestedAmount_IsHalf_AtHalfDuration() public {

        // vm.warp премества времето напред - симулираме, че е минала половин година
        vm.warp(block.timestamp + DURATION / 2);
        assertEq(vesting.vestedAmount(), TOTAL_AMOUNT / 2);

    }

    // After the period end everything should be vested
    function test_VestedAmount_IsFull_AfterDuration() public {
        vm.warp(block.timestamp + DURATION);
        assertEq(vesting.vestedAmount(), TOTAL_AMOUNT);

    }

    // Beneficiary receives the token when release()
    function test_Release_TransfersCorrectAmount() public {

        vm.warp(block.timestamp + DURATION / 2);
        // vm.prank - next call comes "from" beneficiary
        vm.prank(beneficiary);
        vesting.release();
        assertEq(token.balanceOf(beneficiary), TOTAL_AMOUNT / 2);
    }

    // No one except beneficiary can call release()
    function test_Release_RevertsWhen_NotBeneficiary() public {

        vm.warp(block.timestamp + DURATION / 2);
        address stranger = makeAddr("stranger");
        vm.prank(stranger);
        vm.expectRevert("Not the beneficiary");
        vesting.release();

    }

    // If nothing is vested yet, release() should revert-не
    function test_Release_RevertsWhen_NothingToRelease() public {

        vm.prank(beneficiary);
        vm.expectRevert("Nothing to release");
        vesting.release();

    }
}