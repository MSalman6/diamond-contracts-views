// SPDX-License-Identifier: Apache 2.0
pragma solidity =0.8.25;

interface IConnectivityTracker {
    function isFaultyValidator(uint256,address) external view returns (bool);
    function getValidatorConnectivityScore(uint256,address) external view returns (uint256);
}
