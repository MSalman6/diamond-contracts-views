// SPDX-License-Identifier: Apache 2.0
pragma solidity =0.8.25;

interface IValidatorSetHbbft {
    enum KeyGenMode {
        NotAPendingValidator,
        WritePart,
        WaitForOtherParts,
        WriteAck,
        WaitForOtherAcks,
        AllKeysDone
    }

    function bonusScoreSystem() external view returns(address);

    function blockRewardContract() external view returns(address);
    function keyGenHistoryContract() external view returns(address);

    function getValidators() external view returns (address[] memory);
    function getPublicKey(address) external view returns (bytes memory);
    function getPendingValidators() external view returns (address[] memory);

    // require mining address
    function stakingByMiningAddress(address) external view returns (address);
    function miningByStakingAddress(address) external view returns (address);
    function validatorAvailableSince(address) external view returns (uint256);
    function getPendingValidatorKeyGenerationMode(address) external view returns (KeyGenMode);
}
