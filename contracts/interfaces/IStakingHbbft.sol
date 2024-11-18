// SPDX-License-Identifier: Apache 2.0
pragma solidity =0.8.20;

interface IStakingHbbft {
    function stakingEpoch() external view returns (uint256);
    function getPools() external view returns (address[] memory);
    function candidateMinStake() external view returns (uint256);
    function delegatorMinStake() external view returns (uint256);
    function stakingEpochStartTime() external view returns (uint256);
    function stakingEpochStartBlock() external view returns (uint256);
    function areStakeAndWithdrawAllowed() external view returns (bool);
    function stakeAmountTotal(address) external view returns (uint256);
    function stakingFixedEpochEndTime() external view returns (uint256);
    function getPoolsInactive() external view returns (address[] memory);
    function stakingFixedEpochDuration() external view returns (uint256);
    function stakeAmount(address, address) external view returns (uint256);
    function getPoolsToBeElected() external view returns (address[] memory);
    function stakingWithdrawDisallowPeriod() external view returns (uint256);
    function poolDelegators(address) external view returns (address[] memory);
    function orderWithdrawEpoch(address, address) external view returns (uint256);
    function orderedWithdrawAmount(address, address) external view returns (uint256);
}
