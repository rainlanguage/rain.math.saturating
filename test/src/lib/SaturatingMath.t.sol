// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {LibSaturatingMath} from "src/lib/LibSaturatingMath.sol";
import {SaturatingMathHarness} from "test/src/lib/SaturatingMathHarness.sol";

contract SaturatingMathTest is Test {
    /// Panic code solc raises for arithmetic that overflows or underflows.
    uint256 internal constant ARITHMETIC_PANIC = 0x11;

    SaturatingMathHarness internal harness;

    function setUp() external {
        harness = new SaturatingMathHarness();
    }

    /// A draw spread across magnitudes rather than across the range. A uniform
    /// `uint256` sits above `2 ** 255` half the time, which for multiplication
    /// leaves only `0` and `1` as second terms whose product still fits and
    /// collapses the representable half onto trivial products. Drawing the bit
    /// width first and the value within that width second reaches every scale
    /// equally often. `bound` at both steps maps small and near maximal draws
    /// onto the edges of their ranges, so the narrowest widths — where the
    /// saturation boundary is sharpest — stay reachable from the values a
    /// fuzzer proposes most.
    /// @param width Selects the bit width, from `minBits` to 256.
    /// @param x Selects the value within that width.
    /// @param minBits Narrowest bit width to select, at least 1.
    /// @return A value of exactly the selected bit width.
    function magnitude(uint256 width, uint256 x, uint256 minBits) internal pure returns (uint256) {
        uint256 bits = bound(width, minBits, 256);
        uint256 lo = uint256(1) << (bits - 1);
        uint256 hi = bits == 256 ? type(uint256).max : (uint256(1) << bits) - 1;
        return bound(x, lo, hi);
    }

    /// The representable half of `saturatingAdd`. For any first term the sums
    /// that fit are exactly the second terms in `[0, max - a]`, so every draw
    /// lands in the half by construction and none is discarded. The expectation
    /// is checked arithmetic outside any `unchecked` block, so a second term
    /// that did not belong in this half would panic rather than quietly agree
    /// with the library.
    function testNotOverflowAdd(uint256 a, uint256 b) public pure {
        b = bound(b, 0, type(uint256).max - a);

        assertEq(a + b, LibSaturatingMath.saturatingAdd(a, b));
    }

    /// The clamping half of `saturatingAdd`. No second term can overflow a
    /// first term of `0`, so the half begins at `1`, and from there the second
    /// terms that overflow are exactly `[max - a + 1, max]`.
    function testSaturateAdd(uint256 a, uint256 b) public pure {
        a = bound(a, 1, type(uint256).max);
        b = bound(b, type(uint256).max - a + 1, type(uint256).max);

        // The pair overflows, stated without reference to the library.
        assertGt(b, type(uint256).max - a);

        assertEq(type(uint256).max, LibSaturatingMath.saturatingAdd(a, b));
    }

    /// The representable half of `saturatingSub`: the differences that fit are
    /// exactly the subtrahends in `[0, a]`.
    function testNotUnderflowSub(uint256 a, uint256 b) public pure {
        b = bound(b, 0, a);

        assertEq(a - b, LibSaturatingMath.saturatingSub(a, b));
    }

    /// The clamping half of `saturatingSub`. No subtrahend can underflow a
    /// minuend of `max`, so the half ends at `max - 1`, and from there the
    /// subtrahends that underflow are exactly `[a + 1, max]`.
    function testSaturateSub(uint256 a, uint256 b) public pure {
        a = bound(a, 0, type(uint256).max - 1);
        b = bound(b, a + 1, type(uint256).max);

        // The pair underflows, stated without reference to the library.
        assertGt(b, a);

        assertEq(0, LibSaturatingMath.saturatingSub(a, b));
    }

    /// The representable half of `saturatingMul`. A first term of `0` has no
    /// half to explore, since `0 * b` is `0` for every `b`, so the width starts
    /// at one bit, and from there the second terms whose product fits are
    /// exactly `[0, max / a]`.
    function testNotOverflowMul(uint256 width, uint256 a, uint256 b) public pure {
        a = magnitude(width, a, 1);
        b = bound(b, 0, type(uint256).max / a);

        assertEq(a * b, LibSaturatingMath.saturatingMul(a, b));
    }

    /// The clamping half of `saturatingMul`. A first term of `1` multiplies
    /// nothing past the ceiling, so the width starts at two bits, and from
    /// there the second terms that overflow are exactly `[max / a + 1, max]`.
    function testSaturateMul(uint256 width, uint256 a, uint256 b) public pure {
        a = magnitude(width, a, 2);
        b = bound(b, type(uint256).max / a + 1, type(uint256).max);

        // The pair overflows, stated without reference to the library.
        assertGt(b, type(uint256).max / a);

        assertEq(type(uint256).max, LibSaturatingMath.saturatingMul(a, b));
    }

    function testAZeroMul(uint256 b) public pure {
        assertEq(0, LibSaturatingMath.saturatingMul(0, b));
    }

    /// Values at and immediately around every bound the library can saturate
    /// against: zero and its neighbours, the numeric maximum and its
    /// neighbours, and the square root of the modulus, where a product first
    /// stops fitting in a `uint256`.
    function corners() internal pure returns (uint256[] memory xs) {
        xs = new uint256[](15);
        xs[0] = 0;
        xs[1] = 1;
        xs[2] = 2;
        xs[3] = 3;
        xs[4] = type(uint64).max;
        xs[5] = uint256(type(uint128).max) - 1;
        xs[6] = type(uint128).max;
        xs[7] = uint256(type(uint128).max) + 1;
        xs[8] = uint256(type(uint128).max) + 2;
        xs[9] = (uint256(1) << 255) - 1;
        xs[10] = uint256(1) << 255;
        xs[11] = (uint256(1) << 255) + 1;
        xs[12] = type(uint256).max - 2;
        xs[13] = type(uint256).max - 1;
        xs[14] = type(uint256).max;
    }

    /// `saturatingAdd` returns the exact sum whenever the sum is representable
    /// and `type(uint256).max` whenever it is not, with the boundary between
    /// the two decided by solc rather than by the library.
    function checkAdd(uint256 a, uint256 b) internal view {
        uint256 actual = LibSaturatingMath.saturatingAdd(a, b);
        try harness.checkedAdd(a, b) returns (uint256 exact) {
            assertEq(actual, exact, "add: representable sum must be exact");
        } catch Panic(uint256 code) {
            assertEq(code, ARITHMETIC_PANIC, "add: unexpected panic");
            assertEq(actual, type(uint256).max, "add: unrepresentable sum must clamp to max");
        }
    }

    /// `saturatingSub` returns the exact difference whenever the difference is
    /// representable and `0` whenever it is not.
    function checkSub(uint256 a, uint256 b) internal view {
        uint256 actual = LibSaturatingMath.saturatingSub(a, b);
        try harness.checkedSub(a, b) returns (uint256 exact) {
            assertEq(actual, exact, "sub: representable difference must be exact");
        } catch Panic(uint256 code) {
            assertEq(code, ARITHMETIC_PANIC, "sub: unexpected panic");
            assertEq(actual, 0, "sub: unrepresentable difference must clamp to zero");
        }
    }

    /// `saturatingMul` returns the exact product whenever the product is
    /// representable and `type(uint256).max` whenever it is not.
    function checkMul(uint256 a, uint256 b) internal view {
        uint256 actual = LibSaturatingMath.saturatingMul(a, b);
        try harness.checkedMul(a, b) returns (uint256 exact) {
            assertEq(actual, exact, "mul: representable product must be exact");
        } catch Panic(uint256 code) {
            assertEq(code, ARITHMETIC_PANIC, "mul: unexpected panic");
            assertEq(actual, type(uint256).max, "mul: unrepresentable product must clamp to max");
        }
    }

    /// Saturation agrees with solc's own arithmetic across the whole input
    /// domain: exact where the operation is representable, clamped where it is
    /// not. Nothing is filtered out, so the overflowing and non overflowing
    /// halves are both reached without relying on the library's own notion of
    /// which half an input falls in.
    function testAgreesWithCheckedArithmetic(uint256 a, uint256 b) external view {
        checkAdd(a, b);
        checkSub(a, b);
        checkMul(a, b);
    }

    /// Every pair drawn from the bounds and their neighbours, which uniform
    /// fuzzing over `uint256` reaches only by chance.
    function testCornerPairs() external view {
        uint256[] memory xs = corners();
        for (uint256 i = 0; i < xs.length; i++) {
            for (uint256 j = 0; j < xs.length; j++) {
                checkAdd(xs[i], xs[j]);
                checkSub(xs[i], xs[j]);
                checkMul(xs[i], xs[j]);
            }
        }
    }

    /// Sums stated directly, including the largest sum that still fits and the
    /// smallest that does not, so a clamp that lands one short of the maximum
    /// is distinguishable from one that lands on it.
    function testAddEdgeValues() external pure {
        uint256 max = type(uint256).max;
        assertEq(LibSaturatingMath.saturatingAdd(0, 0), 0);
        assertEq(LibSaturatingMath.saturatingAdd(0, 1), 1);
        assertEq(LibSaturatingMath.saturatingAdd(1, 0), 1);
        assertEq(LibSaturatingMath.saturatingAdd(1, 1), 2);
        assertEq(LibSaturatingMath.saturatingAdd(max, 0), max);
        assertEq(LibSaturatingMath.saturatingAdd(0, max), max);
        // Largest representable sums: exact, not saturated.
        assertEq(LibSaturatingMath.saturatingAdd(max - 2, 1), max - 1);
        assertEq(LibSaturatingMath.saturatingAdd(1, max - 2), max - 1);
        assertEq(LibSaturatingMath.saturatingAdd(max - 1, 1), max);
        assertEq(LibSaturatingMath.saturatingAdd((uint256(1) << 255) - 1, uint256(1) << 255), max);
        assertEq(LibSaturatingMath.saturatingAdd((uint256(1) << 255) - 2, uint256(1) << 255), max - 1);
        // Smallest sum that does not fit, and beyond.
        assertEq(LibSaturatingMath.saturatingAdd(max, 1), max);
        assertEq(LibSaturatingMath.saturatingAdd(max, 2), max);
        assertEq(LibSaturatingMath.saturatingAdd(uint256(1) << 255, uint256(1) << 255), max);
        assertEq(LibSaturatingMath.saturatingAdd(max, max), max);
    }

    /// Differences stated directly, including the smallest non zero result at
    /// the top of the range and an underflow by exactly one.
    function testSubEdgeValues() external pure {
        uint256 max = type(uint256).max;
        assertEq(LibSaturatingMath.saturatingSub(0, 0), 0);
        assertEq(LibSaturatingMath.saturatingSub(1, 0), 1);
        assertEq(LibSaturatingMath.saturatingSub(2, 1), 1);
        assertEq(LibSaturatingMath.saturatingSub(max, 0), max);
        assertEq(LibSaturatingMath.saturatingSub(max, 1), max - 1);
        assertEq(LibSaturatingMath.saturatingSub(max, max - 1), 1);
        // Exactly zero, from both directions.
        assertEq(LibSaturatingMath.saturatingSub(1, 1), 0);
        assertEq(LibSaturatingMath.saturatingSub(max, max), 0);
        // Underflow clamps to the floor rather than wrapping to the ceiling.
        assertEq(LibSaturatingMath.saturatingSub(0, 1), 0);
        assertEq(LibSaturatingMath.saturatingSub(1, 2), 0);
        assertEq(LibSaturatingMath.saturatingSub(max - 1, max), 0);
        assertEq(LibSaturatingMath.saturatingSub(0, max), 0);
    }

    /// Products stated directly. `2 * (2 ** 255 - 1)` is the largest product
    /// that still fits and `2 * 2 ** 255` the smallest that does not, so the
    /// two sides of the saturation boundary are pinned one apart.
    function testMulEdgeValues() external pure {
        uint256 max = type(uint256).max;
        assertEq(LibSaturatingMath.saturatingMul(0, 0), 0);
        assertEq(LibSaturatingMath.saturatingMul(0, max), 0);
        assertEq(LibSaturatingMath.saturatingMul(max, 0), 0);
        assertEq(LibSaturatingMath.saturatingMul(1, 1), 1);
        assertEq(LibSaturatingMath.saturatingMul(1, max), max);
        assertEq(LibSaturatingMath.saturatingMul(max, 1), max);
        // Largest representable products: exact, not saturated.
        assertEq(LibSaturatingMath.saturatingMul(2, (uint256(1) << 255) - 1), max - 1);
        assertEq(LibSaturatingMath.saturatingMul((uint256(1) << 255) - 1, 2), max - 1);
        assertEq(LibSaturatingMath.saturatingMul(uint256(1) << 128, type(uint128).max), max - type(uint128).max);
        assertEq(LibSaturatingMath.saturatingMul(type(uint128).max, type(uint128).max), max - (uint256(1) << 129) + 2);
        // Smallest products that do not fit, and beyond.
        assertEq(LibSaturatingMath.saturatingMul(2, uint256(1) << 255), max);
        assertEq(LibSaturatingMath.saturatingMul(uint256(1) << 255, 2), max);
        assertEq(LibSaturatingMath.saturatingMul(uint256(1) << 128, uint256(1) << 128), max);
        assertEq(LibSaturatingMath.saturatingMul(max, 2), max);
        assertEq(LibSaturatingMath.saturatingMul(max, max), max);
    }

    /// Zero is the additive identity in both argument positions.
    function testAddIdentity(uint256 a) external pure {
        assertEq(LibSaturatingMath.saturatingAdd(a, 0), a);
        assertEq(LibSaturatingMath.saturatingAdd(0, a), a);
    }

    /// Subtracting zero is the identity; subtracting a value from itself, or
    /// from anything smaller, is zero.
    function testSubIdentity(uint256 a) external pure {
        assertEq(LibSaturatingMath.saturatingSub(a, 0), a);
        assertEq(LibSaturatingMath.saturatingSub(a, a), 0);
        assertEq(LibSaturatingMath.saturatingSub(0, a), 0);
    }

    /// One is the multiplicative identity and zero the annihilator, in both
    /// argument positions.
    function testMulIdentity(uint256 a) external pure {
        assertEq(LibSaturatingMath.saturatingMul(a, 1), a);
        assertEq(LibSaturatingMath.saturatingMul(1, a), a);
        assertEq(LibSaturatingMath.saturatingMul(a, 0), 0);
        assertEq(LibSaturatingMath.saturatingMul(0, a), 0);
    }

    /// Clamping does not break commutativity, even though the implementations
    /// treat their two arguments asymmetrically.
    function testCommutative(uint256 a, uint256 b) external pure {
        assertEq(LibSaturatingMath.saturatingAdd(a, b), LibSaturatingMath.saturatingAdd(b, a));
        assertEq(LibSaturatingMath.saturatingMul(a, b), LibSaturatingMath.saturatingMul(b, a));
    }

    /// Clamping does not break monotonicity: a larger operand never produces a
    /// smaller sum or product, and a larger subtrahend never produces a larger
    /// difference.
    function testMonotonic(uint256 a, uint256 b, uint256 c) external pure {
        uint256 lo = b;
        uint256 hi = c;
        if (lo > hi) {
            (lo, hi) = (hi, lo);
        }
        assertLe(LibSaturatingMath.saturatingAdd(a, lo), LibSaturatingMath.saturatingAdd(a, hi));
        assertLe(LibSaturatingMath.saturatingMul(a, lo), LibSaturatingMath.saturatingMul(a, hi));
        assertGe(LibSaturatingMath.saturatingSub(a, lo), LibSaturatingMath.saturatingSub(a, hi));
    }

    /// Adding never loses ground and subtracting never gains any, so a clamp
    /// can only ever move a result toward the bound it is clamping at.
    function testDirectionOfSaturation(uint256 a, uint256 b) external pure {
        uint256 sum = LibSaturatingMath.saturatingAdd(a, b);
        assertGe(sum, a);
        assertGe(sum, b);
        assertLe(LibSaturatingMath.saturatingSub(a, b), a);
        uint256 product = LibSaturatingMath.saturatingMul(a, b);
        if (a > 0 && b > 0) {
            assertGe(product, a);
            assertGe(product, b);
        }
    }

    /// The exact branch of each operation, reached by construction rather than
    /// by rejection sampling, so the whole representable range is covered
    /// uniformly instead of only the region a uniform `uint256` fuzzer happens
    /// to land in.
    function testExactBranchAtScale(uint256 a, uint256 b) external pure {
        uint256 max = type(uint256).max;

        uint256 addB = bound(b, 0, max - a);
        assertEq(LibSaturatingMath.saturatingAdd(a, addB), a + addB);

        uint256 subB = bound(b, 0, a);
        assertEq(LibSaturatingMath.saturatingSub(a, subB), a - subB);

        // Held below the square root of the modulus so the product spans the
        // full width rather than collapsing onto a tiny operand.
        uint256 mulA = bound(a, 1, type(uint128).max);
        uint256 mulB = bound(b, 0, max / mulA);
        assertEq(LibSaturatingMath.saturatingMul(mulA, mulB), mulA * mulB);
    }

    /// The clamping branch of each operation, reached by construction.
    function testClampingBranchAtScale(uint256 a, uint256 b) external pure {
        uint256 max = type(uint256).max;

        uint256 addA = bound(a, 1, max);
        assertEq(LibSaturatingMath.saturatingAdd(addA, bound(b, max - addA + 1, max)), max);

        uint256 subA = bound(a, 0, max - 1);
        assertEq(LibSaturatingMath.saturatingSub(subA, bound(b, subA + 1, max)), 0);

        uint256 mulA = bound(a, 2, max);
        assertEq(LibSaturatingMath.saturatingMul(mulA, bound(b, max / mulA + 1, max)), max);
    }

    /// None of the operations reverts, for any input, which is the guarantee
    /// the library exists to provide. Observed across a call boundary so a
    /// revert is a failed call rather than an aborted test, and the value
    /// returned there is checked to match the internal call.
    function testNeverReverts(uint256 a, uint256 b) external view {
        bytes[] memory calls = new bytes[](3);
        calls[0] = abi.encodeCall(SaturatingMathHarness.saturatingAdd, (a, b));
        calls[1] = abi.encodeCall(SaturatingMathHarness.saturatingSub, (a, b));
        calls[2] = abi.encodeCall(SaturatingMathHarness.saturatingMul, (a, b));

        uint256[] memory expected = new uint256[](3);
        expected[0] = LibSaturatingMath.saturatingAdd(a, b);
        expected[1] = LibSaturatingMath.saturatingSub(a, b);
        expected[2] = LibSaturatingMath.saturatingMul(a, b);

        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory data) = address(harness).staticcall(calls[i]);
            assertTrue(success, "saturating operation reverted");
            assertEq(abi.decode(data, (uint256)), expected[i]);
        }
    }

    /// Operands to walk each saturation boundary along. Saturation does not
    /// begin at a single input pair: for addition it begins along `a + b ==
    /// 2 ** 256`, for multiplication along `a * b == 2 ** 256`, and for
    /// subtraction along `a == b`. Sampling a handful of points on those
    /// curves leaves the rest of each one unpinned, so they are walked across
    /// every power of two and its immediate neighbours, plus the small
    /// multipliers where the curves are steepest.
    function boundaryOperands() internal pure returns (uint256[] memory xs) {
        xs = new uint256[](32 + 255 * 3);
        uint256 n = 0;
        for (uint256 i = 1; i <= 32; i++) {
            xs[n++] = i;
        }
        for (uint256 k = 1; k < 256; k++) {
            uint256 p = uint256(1) << k;
            xs[n++] = p - 1;
            xs[n++] = p;
            // `2 ** 255 + 1` is representable; the guard is for `k == 256`,
            // which the loop excludes, so this is always safe.
            xs[n++] = p + 1;
        }
    }

    /// Either side of the largest sum that fits, walked along the whole
    /// addition boundary.
    function testAddSaturationBoundarySweep() external pure {
        uint256 max = type(uint256).max;
        uint256[] memory xs = boundaryOperands();
        for (uint256 i = 0; i < xs.length; i++) {
            uint256 a = xs[i];
            if (a >= max) {
                continue;
            }
            // One below the largest sum that fits: exact.
            assertEq(LibSaturatingMath.saturatingAdd(a, max - a - 1), max - 1);
            // The largest sum that fits: exact, and equal to the ceiling.
            assertEq(LibSaturatingMath.saturatingAdd(a, max - a), max);
            // The smallest sum that does not fit: clamped.
            assertEq(LibSaturatingMath.saturatingAdd(a, max - a + 1), max);
        }
    }

    /// Either side of the point where the difference stops being
    /// representable, walked along the whole subtraction boundary.
    function testSubSaturationBoundarySweep() external pure {
        uint256 max = type(uint256).max;
        uint256[] memory xs = boundaryOperands();
        for (uint256 i = 0; i < xs.length; i++) {
            uint256 a = xs[i];
            // The smallest non zero difference.
            assertEq(LibSaturatingMath.saturatingSub(a, a - 1), 1);
            // Exactly zero, from the exact side.
            assertEq(LibSaturatingMath.saturatingSub(a, a), 0);
            // Underflow by one: clamped to the floor, not wrapped.
            if (a < max) {
                assertEq(LibSaturatingMath.saturatingSub(a, a + 1), 0);
            }
        }
    }

    /// Either side of the largest product that fits, walked along the whole
    /// multiplication boundary. `max / a` is the largest multiplier whose
    /// product with `a` is representable, so `max / a + 1` is the first one
    /// that must clamp.
    function testMulSaturationBoundarySweep() external pure {
        uint256 max = type(uint256).max;
        uint256[] memory xs = boundaryOperands();
        for (uint256 i = 0; i < xs.length; i++) {
            uint256 a = xs[i];
            uint256 fits = max / a;
            // Checked multiplication here, so an expectation that is itself
            // wrong reverts rather than agreeing with a wrong implementation.
            assertEq(LibSaturatingMath.saturatingMul(a, fits), a * fits);
            assertEq(LibSaturatingMath.saturatingMul(fits, a), a * fits);
            if (a > 1) {
                assertEq(LibSaturatingMath.saturatingMul(a, fits + 1), max);
                assertEq(LibSaturatingMath.saturatingMul(fits + 1, a), max);
            }
        }
    }

    /// The same guarantee at the bounds themselves.
    function testNeverRevertsAtCorners() external view {
        uint256[] memory xs = corners();
        for (uint256 i = 0; i < xs.length; i++) {
            for (uint256 j = 0; j < xs.length; j++) {
                checkNeverReverts(xs[i], xs[j]);
            }
        }
    }

    function checkNeverReverts(uint256 a, uint256 b) internal view {
        (bool addOk,) = address(harness).staticcall(abi.encodeCall(SaturatingMathHarness.saturatingAdd, (a, b)));
        assertTrue(addOk, "add reverted");
        (bool subOk,) = address(harness).staticcall(abi.encodeCall(SaturatingMathHarness.saturatingSub, (a, b)));
        assertTrue(subOk, "sub reverted");
        (bool mulOk,) = address(harness).staticcall(abi.encodeCall(SaturatingMathHarness.saturatingMul, (a, b)));
        assertTrue(mulOk, "mul reverted");
    }
}
