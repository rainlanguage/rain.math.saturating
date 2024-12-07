// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibSaturatingMath} from "src/lib/LibSaturatingMath.sol";

contract SaturatingMathTest is Test {
    function testNotOverflowAdd(uint256 a, uint256 b) public pure {
        unchecked {
            uint256 c = a + b;
            vm.assume(c >= a);
        }

        assertEq(a + b, LibSaturatingMath.saturatingAdd(a, b));
    }

    function testSaturateAdd(uint256 a, uint256 b) public pure {
        unchecked {
            uint256 c = a + b;
            vm.assume(c < a);
        }

        assertEq(type(uint256).max, LibSaturatingMath.saturatingAdd(a, b));
    }

    function testNotUnderflowSub(uint256 a, uint256 b) public pure {
        unchecked {
            uint256 c = a - b;
            vm.assume(c <= a);
        }

        assertEq(a - b, LibSaturatingMath.saturatingSub(a, b));
    }

    function testSaturateSub(uint256 a, uint256 b) public pure {
        unchecked {
            uint256 c = a - b;
            vm.assume(c > a);

            assertEq(0, LibSaturatingMath.saturatingSub(a, b));
        }
    }

    function testNotOverflowMul(uint256 a, uint256 b) public pure {
        unchecked {
            uint256 c = a * b;
            vm.assume(a != 0);
            vm.assume(c / a == b);
        }

        assertEq(a * b, LibSaturatingMath.saturatingMul(a, b));
    }

    function testSaturateMul(uint256 a, uint256 b) public pure {
        unchecked {
            uint256 c = a * b;
            vm.assume(a != 0);
            vm.assume(c / a != b);
        }

        assertEq(type(uint256).max, LibSaturatingMath.saturatingMul(a, b));
    }

    function testAZeroMul(uint256 b) public pure {
        assertEq(0, LibSaturatingMath.saturatingMul(0, b));
    }
}
