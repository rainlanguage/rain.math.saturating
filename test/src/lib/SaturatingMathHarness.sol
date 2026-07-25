// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibSaturatingMath} from "src/lib/LibSaturatingMath.sol";

/// @title SaturatingMathHarness
/// @notice External surface used as an oracle for `LibSaturatingMath`.
///
/// The `checked*` functions carry no `unchecked` block, so solc emits its own
/// overflow and underflow guards: each one returns the exact mathematical
/// result when it fits in a `uint256` and panics with `0x11` when it does not.
/// That makes the saturation boundary observable from the language itself
/// rather than from the same predicates the library under test uses to detect
/// it.
///
/// The `saturating*` functions expose the library across a call boundary, so
/// the documented guarantee that it never reverts is observable as call
/// success rather than as an aborted test.
contract SaturatingMathHarness {
    function checkedAdd(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    function checkedSub(uint256 a, uint256 b) external pure returns (uint256) {
        return a - b;
    }

    function checkedMul(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    function saturatingAdd(uint256 a, uint256 b) external pure returns (uint256) {
        return LibSaturatingMath.saturatingAdd(a, b);
    }

    function saturatingSub(uint256 a, uint256 b) external pure returns (uint256) {
        return LibSaturatingMath.saturatingSub(a, b);
    }

    function saturatingMul(uint256 a, uint256 b) external pure returns (uint256) {
        return LibSaturatingMath.saturatingMul(a, b);
    }
}
