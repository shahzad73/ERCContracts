
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";


/// @notice Atomic peer-to-peer token swap using Permit2 SignatureTransfer.
/// @dev Intended for allowlisted, conventional, non-rebasing ERC-20 tokens.
///      Token allowlisting should be enforced by deployment/governance or
///      added directly to this contract before production use.
contract RWAPeerSwap is ReentrancyGuard {
    using SafeERC20 for IERC20;

    ISignatureTransfer public immutable permit2;

    mapping(bytes32 => bool) public executed;

    bytes32 public constant SWAP_WITNESS_TYPEHASH =
        keccak256(
            "SwapWitness(address verifyingContract,uint256 chainId,"
            "bytes32 swapId,address partyA,address partyB,"
            "address tokenA,address tokenB,uint256 amountA,"
            "uint256 amountB,uint256 deadline)"
        );

    // Permit2 prepends:
    // PermitWitnessTransferFrom(TokenPermissions permitted,
    // address spender,uint256 nonce,uint256 deadline,
    // SwapWitness witness)
    //
    // This string supplies the witness suffix and dependencies.
    string public constant WITNESS_TYPE_STRING =
        "SwapWitness witness)"
        "SwapWitness(address verifyingContract,uint256 chainId,"
        "bytes32 swapId,address partyA,address partyB,"
        "address tokenA,address tokenB,uint256 amountA,"
        "uint256 amountB,uint256 deadline)"
        "TokenPermissions(address token,uint256 amount)";

    struct Swap {
        bytes32 swapId;
        address partyA;
        address partyB;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 deadline;
    }

    event SwapExecuted(
        bytes32 indexed swapId,
        address indexed partyA,
        address indexed partyB,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    );

    error InvalidAddress();
    error InvalidSwap();
    error Expired();
    error AlreadyExecuted();
    error InvalidPermit();
    error UnsupportedToken();
    error UnsupportedTokenBehavior();
    error IncorrectReceipt();

    constructor(address permit2Address) {
        if (
            permit2Address == address(0) ||
            permit2Address.code.length == 0
        ) {
            revert InvalidAddress();
        }

        permit2 = ISignatureTransfer(permit2Address);
    }

    /// @notice Computes the EIP-712 struct hash of the swap witness.
    /// @dev The frontend must compute exactly the same hash.
    function hashWitness(
        Swap calldata s
    ) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                SWAP_WITNESS_TYPEHASH,
                address(this),
                block.chainid,
                s.swapId,
                s.partyA,
                s.partyB,
                s.tokenA,
                s.tokenB,
                s.amountA,
                s.amountB,
                s.deadline
            )
        );
    }

    function executeSwap(
        Swap calldata s,
        ISignatureTransfer.PermitTransferFrom calldata permitA,
        bytes calldata signatureA,
        ISignatureTransfer.PermitTransferFrom calldata permitB,
        bytes calldata signatureB
    ) external nonReentrant {
        // Validate swap terms.
        if (
            s.swapId == bytes32(0) ||
            s.partyA == address(0) ||
            s.partyB == address(0) ||
            s.partyA == s.partyB ||
            s.tokenA == address(0) ||
            s.tokenB == address(0) ||
            s.tokenA == s.tokenB ||
            s.amountA == 0 ||
            s.amountB == 0
        ) {
            revert InvalidSwap();
        }

        if (block.timestamp > s.deadline) revert Expired();
        if (executed[s.swapId]) revert AlreadyExecuted();

        // Enforce exact token and amount authorizations.
        if (
            permitA.permitted.token != s.tokenA ||
            permitA.permitted.amount != s.amountA ||
            permitB.permitted.token != s.tokenB ||
            permitB.permitted.amount != s.amountB ||
            permitA.deadline < s.deadline ||
            permitB.deadline < s.deadline ||
            permitA.deadline < block.timestamp ||
            permitB.deadline < block.timestamp ||
            permitA.nonce == permitB.nonce
                && s.partyA == s.partyB
        ) {
            revert InvalidPermit();
        }

        IERC20 tokenA = IERC20(s.tokenA);
        IERC20 tokenB = IERC20(s.tokenB);

        // Reject addresses that do not contain token code.
        if (
            s.tokenA.code.length == 0 ||
            s.tokenB.code.length == 0
        ) {
            revert UnsupportedToken();
        }

        bytes32 witness = hashWitness(s);

        // Effects before external calls. A revert later in the
        // transaction rolls this state change back atomically.
        executed[s.swapId] = true;

        uint256 aBefore = tokenA.balanceOf(s.partyB);
        uint256 bBefore = tokenB.balanceOf(s.partyA);

        // Party A transfers token A to party B.
        permit2.permitWitnessTransferFrom(
            permitA,
            ISignatureTransfer.SignatureTransferDetails({
                to: s.partyB,
                requestedAmount: s.amountA
            }),
            s.partyA,
            witness,
            WITNESS_TYPE_STRING,
            signatureA
        );

        // Party B transfers token B to party A.
        permit2.permitWitnessTransferFrom(
            permitB,
            ISignatureTransfer.SignatureTransferDetails({
                to: s.partyA,
                requestedAmount: s.amountB
            }),
            s.partyB,
            witness,
            WITNESS_TYPE_STRING,
            signatureB
        );

        // Enforce exact receipt for conventional ERC-20 tokens.
        uint256 aAfter = tokenA.balanceOf(s.partyB);
        uint256 bAfter = tokenB.balanceOf(s.partyA);

        if (aAfter < aBefore || bAfter < bBefore) {
            revert IncorrectReceipt();
        }

        if (
            aAfter - aBefore != s.amountA ||
            bAfter - bBefore != s.amountB
        ) {
            revert UnsupportedTokenBehavior();
        }

        emit SwapExecuted(
            s.swapId,
            s.partyA,
            s.partyB,
            s.tokenA,
            s.tokenB,
            s.amountA,
            s.amountB
        );
    }
}
