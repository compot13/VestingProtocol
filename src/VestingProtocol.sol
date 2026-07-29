// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VestingProtocol {
    using SafeERC20 for IERC20;

    address public immutable beneficiary;
    IERC20 public immutable token;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public totalAmount;
    uint256 public released;
    // default duration removed; duration is set in the constructor

    constructor(
        address _beneficiary,
        address _token,
        //uint256 _start,
        uint256 _duration,
        uint256 _totalAmount
    ) {
        require(_beneficiary != address(0), "Beneficiary cannot be address zero");
        require(_token != address(0), "Token cannot be address zero");
        require(_duration > 0, "Duration cannot be zero");
        require(_totalAmount > 0, "Amount cannot be zero");

        _duration = 365 days;

        beneficiary = _beneficiary;
        token = IERC20(_token);
        start = block.timestamp;
        duration = _duration;
        totalAmount = _totalAmount;
    }

    function release() public {
        require(msg.sender == beneficiary, "Not the beneficiary");

        uint256 releasable = releasableAmount();
        require(releasable > 0, "Nothing to release");

        released += releasable;
        token.safeTransfer(beneficiary, releasable);
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalAmount;
        } else {
            return (totalAmount * (block.timestamp - start)) / duration;
        }
    }

    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - released;
    }
}