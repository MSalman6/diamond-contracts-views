// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IValidatorSetHbbft {
    enum KeyGenMode {
        NotAPendingValidator,
        WritePart,
        WaitForOtherParts,
        WriteAck,
        WaitForOtherAcks,
        AllKeysDone
    }

    function blockRewardContract() external view returns(address);
    function keyGenHistoryContract() external view returns(address);

    function getValidators() external view returns (address[] memory);
    function getPublicKey(address) external view returns (bytes memory);
    function getPendingValidators() external view returns (address[] memory);

    // require mining address
    function banCounter(address) external view returns (uint256);
    function bannedUntil(address) external view returns (uint256);
    function miningByStakingAddress(address) external view returns (address);
    function validatorAvailableSince(address) external view returns (uint256);
    function getPendingValidatorKeyGenerationMode(address) external view returns (KeyGenMode);
}

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

interface ITxPermission {
    function minimumGasPrice() external view returns (uint256);
}

interface IKeyGenHistory {
    function getCurrentKeyGenRound() external view returns (uint256);
}

interface IBlockRewardHbbft {
    function deltaPot() external view returns (uint256);
    function reinsertPot() external view returns (uint256);
}

contract DMDAggregator {
    address public owner;
    IStakingHbbft public st;
    ITxPermission public tp;
    IKeyGenHistory public kh;
    IBlockRewardHbbft public br;
    IValidatorSetHbbft public vs;
    
    constructor(address _st, address _vs, address _tp) {
        owner = msg.sender;
        st = IStakingHbbft(_st);
        tp = ITxPermission(_tp);
        vs = IValidatorSetHbbft(_vs);
        kh = IKeyGenHistory(vs.keyGenHistoryContract());
        br = IBlockRewardHbbft(vs.blockRewardContract());
    }

    struct Pools {
        address[] activePools;
        address[] validators;
        address[] inActivePools;
        address[] poolsToBeElected;
        address[] pendingValidators;
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
        uint256 banCount;
        uint256 bannedUntil;
        uint256 availableSince;
        bytes publicKey;
        address[] delegators;
        IValidatorSetHbbft.KeyGenMode keygenMode;
        uint256 stakedAmountTotal;
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

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
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
        pools = Pools({
            activePools: st.getPools(),
            validators: vs.getValidators(),
            inActivePools: st.getPoolsInactive(),
            poolsToBeElected: st.getPoolsToBeElected(),
            pendingValidators: vs.getPendingValidators()
        });
    }

    function getPoolsData(address[] memory _sAs) external view returns (PoolData[] memory poolsData) {
        poolsData = new PoolData[](_sAs.length);

        for (uint256 i = 0; i < _sAs.length; i++) {
            address miningAddress = vs.miningByStakingAddress(_sAs[i]);
            poolsData[i] = PoolData({
                miningAddress: miningAddress,
                banCount: vs.banCounter(miningAddress),
                bannedUntil: vs.bannedUntil(miningAddress),
                availableSince: vs.validatorAvailableSince(miningAddress),
                publicKey: vs.getPublicKey(miningAddress),
                delegators: st.poolDelegators(_sAs[i]),
                keygenMode: vs.getPendingValidatorKeyGenerationMode(miningAddress),
                stakedAmountTotal: st.stakeAmountTotal(_sAs[i])
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
}

// Staking: 0x1100000000000000000000000000000000000001
// ValidatorSet: 0x1000000000000000000000000000000000000001
// TxPermisson: 0x4000000000000000000000000000000000000001