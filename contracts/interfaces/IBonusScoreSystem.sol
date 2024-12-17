// SPDX-License-Identifier: Apache 2.0
pragma solidity =0.8.25;

interface IBonusScoreSystem {
    function connectivityTracker() external view returns (address);
    function getValidatorScore(address) external view returns (uint256);
}
