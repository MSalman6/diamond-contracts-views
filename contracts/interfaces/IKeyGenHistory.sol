// SPDX-License-Identifier: Apache 2.0
pragma solidity =0.8.20;

interface IKeyGenHistory {
    function getCurrentKeyGenRound() external view returns (uint256);
}
