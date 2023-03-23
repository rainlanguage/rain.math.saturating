// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import "../src/SaturatingMath.sol";

contract SaturatingMathTest is Test {
    function testNotOverflowAdd(uint256 a_, uint256 b_) public {
        unchecked {
            uint256 c_ = a_ + b_;
            vm.assume(c_ >= a_);
        }

        assertEq(a_ + b_, SaturatingMath.saturatingAdd(a_, b_));
    }

    function testSaturateAdd(uint256 a_, uint256 b_) public {
        unchecked {
            uint256 c_ = a_ + b_;
            vm.assume(c_ < a_);
        }

        assertEq(type(uint256).max, SaturatingMath.saturatingAdd(a_, b_));
    }

    function testNotUnderflowSub(uint256 a_, uint256 b_) public {
        unchecked {
            uint256 c_ = a_ - b_;
            vm.assume(c_ <= a_);
        }

        assertEq(a_ - b_, SaturatingMath.saturatingSub(a_, b_));
    }

    function testSaturateSub(uint256 a_, uint256 b_) public {
        unchecked {
            uint256 c_ = a_ - b_;
            vm.assume(c_ > a_);

            assertEq(0, SaturatingMath.saturatingSub(a_, b_));
        }
    }

    function testNotOverflowMul(uint256 a_, uint256 b_) public {
        unchecked {
            uint256 c_ = a_ * b_;
            vm.assume(a_ != 0);
            vm.assume(c_ / a_ == b_);
        }

        assertEq(a_ * b_, SaturatingMath.saturatingMul(a_, b_));
    }

    function testSaturateMul(uint256 a_, uint256 b_) public {
        unchecked {
            uint256 c_ = a_ * b_;
            vm.assume(a_ != 0);
            vm.assume(c_ / a_ != b_);
        }

        assertEq(type(uint256).max, SaturatingMath.saturatingMul(a_, b_));
    }

    function testAZeroMul(uint256 b_) public {
        assertEq(0, SaturatingMath.saturatingMul(0, b_));
    }
}
