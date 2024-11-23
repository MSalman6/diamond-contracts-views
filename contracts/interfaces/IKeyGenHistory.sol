// SPDX-License-Identifier: Apache 2.0
pragma solidity =0.8.25;

interface IKeyGenHistory {
    function getCurrentKeyGenRound() external view returns (uint256);
}
