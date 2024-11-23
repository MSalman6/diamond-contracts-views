// SPDX-License-Identifier: Apache 2.0
pragma solidity =0.8.25;

interface ITxPermission {
    function minimumGasPrice() external view returns (uint256);
}
