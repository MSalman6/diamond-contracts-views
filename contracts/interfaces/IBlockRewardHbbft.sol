// SPDX-License-Identifier: Apache 2.0
pragma solidity =0.8.20;

interface IBlockRewardHbbft {
    function deltaPot() external view returns (uint256);
    function reinsertPot() external view returns (uint256);
}