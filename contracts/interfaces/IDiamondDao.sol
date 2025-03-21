// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.25;

import { DaoPhase, Phase, Proposal, ProposalState, Vote, VotingResult } from "../library/DaoStructs.sol";

interface IDiamondDao {
    event ProposalCreated(
        address indexed proposer,
        uint256 indexed proposalId,
        address[] targets,
        uint256[] values,
        bytes[] calldatas,
        string title,
        string description,
        string discussionUrl,
        uint256 proposalFee
    );

    event ProposalCanceled(address indexed proposer, uint256 indexed proposalId, string reason);

    event ProposalExecuted(address indexed caller, uint256 indexed proposalId);

    event VotingFinalized(address indexed caller, uint256 indexed proposalId, bool indexed accepted);

    event SubmitVote(address indexed voter, uint256 indexed proposalId, Vote indexed vote);

    event SubmitVoteWithReason(
        address indexed voter,
        uint256 indexed proposalId,
        Vote indexed vote,
        string reason
    );

    event ChangeVote(address indexed voter, uint256 indexed proposalId, Vote indexed vote, string reason);

    event SwitchDaoPhase(Phase indexed phase, uint256 indexed start, uint256 indexed end);

    event SetCreateProposalFee(uint256 indexed fee);

    event SetIsCoreContract(address indexed contractAddress, bool indexed isCore);

    event SetChangeAbleParameters(bool indexed allowed, string setter, string getter, uint256[] params);

    error InsufficientFunds();
    error InvalidArgument();
    error InvalidStartTimestamp();
    error NewProposalsLimitExceeded();
    error OnlyGovernance();
    error OnlyProposer();
    error OnlyValidators(address caller);
    error ProposalAlreadyExist(uint256 proposalId);
    error ProposalNotExist(uint256 proposalId);
    error TransferFailed(address from, address to, uint256 amount);
    error UnavailableInCurrentPhase(Phase phase);
    error UnexpectedProposalState(uint256 proposalId, ProposalState state);
    error ContractCallFailed(bytes funcSelector, address targetContract);
    error UnfinalizedProposalsExist();
    error OutsideExecutionWindow(uint256 proposalId);
    error NotProposer(uint256 proposalId, address caller);
    error SameVote(uint256 proposalId, address vote, Vote _vote);
    error AlreadyVoted(uint256 proposalId, address voter);
    error NoVoteFound(uint256 proposalId, address voter);

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory title,
        string memory description,
        string memory discussionUrl
    ) external payable;

    function cancel(uint256 proposalId, string calldata reason) external;

    function vote(uint256 proposalId, Vote _vote) external;

    function voteWithReason(uint256 proposalId, Vote _vote, string calldata reason) external;

    function finalize(uint256 proposalId) external;

    function execute(uint256 proposalId) external;

    function proposalExists(uint256 proposalId) external view returns (bool);

    function getProposal(uint256 proposalId) external view returns (Proposal memory);

    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory descriptionHash
    ) external pure returns (uint256);

    function daoPhaseCount() external view returns (uint256);

    function daoPhase() external view returns (DaoPhase memory);

    function createProposalFee() external view returns (uint256);

    function getProposalVotersCount(uint256 proposalId) external view returns (uint256);

    function countVotes(uint256 proposalId) external view returns (VotingResult memory);

    function getProposalVoters(uint256 proposalId) external view returns (address[] memory);

    function currentPhaseProposals() external view returns (uint256[] memory);

    function daoEpochTotalStakeSnapshot(uint256 daoEpoch) external view returns (uint256);

    function daoPhaseProposals(uint256 daoPhase) external view returns (uint256[] memory);
}
