// SPDX-License-Identifier: Apache 2.0
pragma solidity =0.8.25;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IStakingHbbft } from "./interfaces/IStakingHbbft.sol";
import { ITxPermission } from "./interfaces/ITxPermission.sol";
import { IKeyGenHistory } from "./interfaces/IKeyGenHistory.sol";
import { IBlockRewardHbbft } from "./interfaces/IBlockRewardHbbft.sol";
import { IBonusScoreSystem } from "./interfaces/IBonusScoreSystem.sol";
import { IValidatorSetHbbft } from "./interfaces/IValidatorSetHbbft.sol";
import { IConnectivityTracker } from "./interfaces/IConnectivityTracker.sol";

contract DMDAggregator is Ownable {
    IStakingHbbft st;
    ITxPermission tp;
    IKeyGenHistory kh;
    IBlockRewardHbbft br;
    IBonusScoreSystem bs;
    IValidatorSetHbbft vs;
    IConnectivityTracker ct;

    constructor(address initialOwner, address _st, address _vs, address _tp) Ownable(initialOwner) {
        st = IStakingHbbft(_st);
        tp = ITxPermission(_tp);
        vs = IValidatorSetHbbft(_vs);
        bs = IBonusScoreSystem(vs.bonusScoreSystem());
        kh = IKeyGenHistory(vs.keyGenHistoryContract());
        br = IBlockRewardHbbft(vs.blockRewardContract());
        ct = IConnectivityTracker(bs.connectivityTracker());
    }

    struct Pools {
        address[] stActivePools;
        address[] stInActivePools;
        address[] stPoolsToBeElected;
        address[] vsValidatorsMiningAddresses;
        address[] vsValidatorsStakingAddresses;
        address[] vsPendingValidatorsMiningAddresses;
        address[] vsPendingValidatorsStakingAddresses;
    }

    struct GlobalsData {
        uint256 deltaPot;
        uint256 reinsertPot;
        uint256 keygenRound;
        uint256 stakingEpoch;
        uint256 minimumGasPrice;
        uint256 candidateMinStake;
        uint256 delegatorMinStake;
        uint256 stakingEpochStartTime;
        uint256 stakingEpochStartBlock;
        bool areStakeAndWithdrawAllowed;
        uint256 stakingFixedEpochEndTime;
        uint256 stakingFixedEpochDuration;
        uint256 stakingWithdrawDisallowPeriod;
    }

    struct PoolData {
        address miningAddress;
        uint256 availableSince;
        bytes publicKey;
        address[] delegators;
        IValidatorSetHbbft.KeyGenMode keygenMode;
        uint256 stakedAmountTotal;
        bool isFaultyValidator;
        uint256 validatorScore;
        uint256 connectivityScore;
    }

    struct StakeData {
        address pool;
        uint256 myStakedAmount;
        uint256 stakedAmountTotal;
    }

    struct OrderedWithdrawData {
        address pool;
        uint256 orderedAmount;
        uint256 withdrawEpoch;
    }

    struct DelegateData {
        address delegator;
        uint256 delegatedAmount;
    }

    enum ProposalState {
        Created,
        Canceled,
        Active,
        VotingFinished,
        Accepted,
        Declined,
        Executed
    }

    enum ProposalType {
        Open,
        ContractUpgrade,
        EcosystemParameterChange
    }

    struct Proposal {
        address proposer;
        uint64 votingDaoEpoch;
        ProposalState state;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        string title;
        string description;
        string discussionUrl;
        uint256 daoPhaseCount;
        ProposalType proposalType;
    }

    // SETTERS
    function setStakingContract(address _st) external onlyOwner {
        st = IStakingHbbft(_st);
    }

    function setValidatorsSetContract(address _vs) external onlyOwner {
        vs = IValidatorSetHbbft(_vs);
    }

    function setTxPermissionContract(address _tp) external onlyOwner {
        tp = ITxPermission(_tp);
    }

    function setKeygenHistoryContract(address _kh) external onlyOwner {
        kh = IKeyGenHistory(_kh);
    }

    function setBlockRewardContract(address _br) external onlyOwner {
        br = IBlockRewardHbbft(_br);
    }

    // GETTERS
    function getAllPools() external view returns (Pools memory pools) {
        address[] memory vsValidatorsMiningAddresses = vs.getValidators();
        address[] memory vsPendingValidatorsMiningAddresses = vs.getPendingValidators();
        
        address[] memory vsValidatorsStakingAddresses = getStakingAddresses(vsValidatorsMiningAddresses);
        address[] memory vsPendingValidatorsStakingAddresses = getStakingAddresses(vsPendingValidatorsMiningAddresses);

        pools = Pools({
            stActivePools: st.getPools(),
            stInActivePools: st.getPoolsInactive(),
            stPoolsToBeElected: st.getPoolsToBeElected(),
            vsValidatorsMiningAddresses: vsValidatorsMiningAddresses,
            vsValidatorsStakingAddresses: vsValidatorsStakingAddresses,
            vsPendingValidatorsMiningAddresses: vsPendingValidatorsMiningAddresses,
            vsPendingValidatorsStakingAddresses: vsPendingValidatorsStakingAddresses
        });
    }

    function getPoolsData(address[] memory _sAs) external view returns (PoolData[] memory poolsData) {
        poolsData = new PoolData[](_sAs.length);

        for (uint256 i = 0; i < _sAs.length; i++) {
            uint256 stakingEpoch = st.stakingEpoch();
            address miningAddress = vs.miningByStakingAddress(_sAs[i]);
            poolsData[i] = PoolData({
                miningAddress: miningAddress,
                availableSince: vs.validatorAvailableSince(miningAddress),
                publicKey: vs.getPublicKey(miningAddress),
                delegators: st.poolDelegators(_sAs[i]),
                keygenMode: vs.getPendingValidatorKeyGenerationMode(miningAddress),
                stakedAmountTotal: st.stakeAmountTotal(_sAs[i]),
                isFaultyValidator: ct.isFaultyValidator(stakingEpoch, miningAddress),
                validatorScore: bs.getValidatorScore(miningAddress),
                connectivityScore: ct.getValidatorConnectivityScore(stakingEpoch, miningAddress)
            });
        }
    }

    function getUserStakes(address _user, address[] calldata _pools) external view returns(StakeData[] memory _stakesData) {
        _stakesData = new StakeData[](_pools.length);

        for (uint256 i = 0; i < _pools.length; i++) {
            _stakesData[i] = StakeData({
                pool: _pools[i],
                myStakedAmount: st.stakeAmount(_pools[i], _user),
                stakedAmountTotal: st.stakeAmountTotal(_pools[i])
            });
        }
    }

    function getUserOrderedWithdraws(address _user, address[] calldata _pools) external view returns(OrderedWithdrawData[] memory _stakesData) {
        _stakesData = new OrderedWithdrawData[](_pools.length);

        for (uint256 i = 0; i < _pools.length; i++) {
            _stakesData[i] = OrderedWithdrawData({
                pool: _pools[i],
                orderedAmount: st.orderedWithdrawAmount(_pools[i], _user),
                withdrawEpoch: st.orderWithdrawEpoch(_pools[i], _user)
            });
        }
    }

    function getGlobals() external view returns (GlobalsData memory _globalsData) {
        _globalsData = GlobalsData({
            deltaPot: br.deltaPot(),
            reinsertPot: br.reinsertPot(),
            keygenRound: kh.getCurrentKeyGenRound(),
            stakingEpoch: st.stakingEpoch(),
            minimumGasPrice: tp.minimumGasPrice(),
            candidateMinStake: st.candidateMinStake(),
            delegatorMinStake: st.delegatorMinStake(),
            stakingEpochStartTime: st.stakingEpochStartTime(),
            stakingEpochStartBlock: st.stakingEpochStartBlock(),
            areStakeAndWithdrawAllowed: st.areStakeAndWithdrawAllowed(),
            stakingFixedEpochEndTime: st.stakingFixedEpochEndTime(),
            stakingFixedEpochDuration: st.stakingFixedEpochDuration(),
            stakingWithdrawDisallowPeriod: st.stakingWithdrawDisallowPeriod()
        });
    }

    function getDelegationsData(address[] memory delegators, address poolAddress) external view returns (DelegateData[] memory _delegatesData, uint256 _ownStake, uint256 _candidateStake) {
        _delegatesData = new DelegateData[](delegators.length);

        for (uint256 i; i < delegators.length; i++) {
            address delegatorAddress = delegators[i];
            uint256 delegatedAmount = st.stakeAmount(poolAddress, delegatorAddress);
            _delegatesData[i] = DelegateData({
                delegator: delegatorAddress,
                delegatedAmount: delegatedAmount
            });
            if (poolAddress != delegatorAddress) _candidateStake += delegatedAmount;
        }

        _ownStake = st.stakeAmountTotal(poolAddress) - _candidateStake;
    }

    function getStakingAddresses(address[] memory miningAddresses) 
        public 
        view 
        returns (address[] memory)
    {
        address[] memory stakingAddresses = new address[](miningAddresses.length);
        
        for (uint256 i = 0; i < miningAddresses.length; i++) {
            stakingAddresses[i] = vs.stakingByMiningAddress(miningAddresses[i]);
        }
        
        return stakingAddresses;
    }

    function getNodeOperatorData(address stakingAddress) external view returns (address, uint256) {
        address operator = st.poolNodeOperator(stakingAddress);
        uint256 share = st.poolNodeOperatorShare(stakingAddress);
        return (operator, share);
    }

    function getWithdrawableAmounts(address poolStAddress, address user) external view returns (uint256, uint256) {
        uint256 maxWithdrawAmount = st.maxWithdrawAllowed(poolStAddress, user);
        uint256 maxWithdrawOrderAmount = st.maxWithdrawOrderAllowed(poolStAddress, user);
        return (maxWithdrawAmount, maxWithdrawOrderAmount);
    }
}