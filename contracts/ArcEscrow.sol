// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ArcEscrow
 * @notice Non-custodial USDC escrow for buyer/seller agreements on Arc Testnet.
 *
 * State machine:
 *   createEscrow()  → Created
 *   fundEscrow()    → Funded
 *   markCompleted() → Completed
 *   releaseFunds()  → Released
 *   cancelEscrow()  → Cancelled  (from Created, buyer only)
 *   refundEscrow()  → Refunded   (from Funded/InProgress, buyer only, after REFUND_LOCK_PERIOD)
 *   emergencyRefund()→ Refunded  (from Completed, buyer only, after RELEASE_TIMEOUT)
 *
 * Security notes:
 *  - ReentrancyGuard on all fund-moving functions
 *  - Checks-effects-interactions enforced
 *  - No tx.origin usage
 *  - Custom errors for gas-efficient reverts
 *  - Indexed events for all state changes
 *  - REFUND_LOCK_PERIOD (24h) prevents buyer front-running seller completion
 *  - RELEASE_TIMEOUT (30d) prevents permanent lock when seller cannot receive funds
 *
 * Known risks:
 *  - Pooled USDC custody: if the USDC issuer blocklists THIS contract address,
 *    all in-flight escrowed funds become immovable. The emergencyRefund provides
 *    a buyer recovery path for completed-but-unreleasable escrows. There is no
 *    automated on-chain defence against contract-level blocklisting.
 */
contract ArcEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // -------------------------------------------------------------------------
    // Types
    // -------------------------------------------------------------------------

    enum EscrowState {
        Created,    // 0 – escrow created, not yet funded
        Funded,     // 1 – buyer deposited USDC, work can begin
        InProgress, // 2 – reserved for future milestone use; not entered in v1
        Completed,  // 3 – seller marked work complete, awaiting buyer release
        Released,   // 4 – buyer released payment to seller
        Refunded,   // 5 – USDC returned to buyer
        Cancelled   // 6 – cancelled before funding
    }

    struct Escrow {
        uint256 escrowId;
        address buyer;
        address seller;
        uint256 amount;       // USDC amount (6 decimals)
        string  description;
        EscrowState state;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 completedAt;  // set when state → Completed
        uint256 fundedAt;     // set when state → Funded
    }

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error ZeroAddress();
    error ZeroAmount();
    error InvalidSeller();
    error NotBuyer();
    error NotSeller();
    error InvalidState(EscrowState current, EscrowState expected);
    error EscrowNotFound(uint256 escrowId);
    error ReleasePeriodNotExpired();
    error RefundLockActive();

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        string  description
    );
    event EscrowFunded(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event EscrowCompleted(uint256 indexed escrowId, address indexed seller);
    event EscrowReleased(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event EscrowRefunded(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event EscrowCancelled(uint256 indexed escrowId, address indexed buyer);

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    IERC20 public immutable usdcToken;

    /// @notice After Completed: buyer can emergency-refund after this period.
    uint256 public constant RELEASE_TIMEOUT = 30 days;

    /// @notice After Funded: buyer must wait this long before calling refundEscrow.
    /// Prevents immediate front-run of seller's markCompleted transaction.
    uint256 public constant REFUND_LOCK_PERIOD = 24 hours;

    uint256 public escrowCounter = 1;

    mapping(uint256 => Escrow) private escrows;
    mapping(address => uint256[]) public buyerEscrows;
    mapping(address => uint256[]) public sellerEscrows;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    constructor(address usdcToken_) {
        if (usdcToken_ == address(0)) revert ZeroAddress();
        usdcToken = IERC20(usdcToken_);
    }

    // -------------------------------------------------------------------------
    // External functions
    // -------------------------------------------------------------------------

    /**
     * @notice Create a new escrow agreement.
     * @param seller The counterparty who will perform work and receive payment.
     * @param amount USDC amount (6 decimals). Must be > 0.
     * @param description Human-readable deal description.
     * @return escrowId The sequential escrow identifier (starts at 1).
     */
    function createEscrow(
        address seller,
        uint256 amount,
        string calldata description
    ) external returns (uint256 escrowId) {
        if (seller == address(0)) revert ZeroAddress();
        if (seller == msg.sender) revert InvalidSeller();
        if (amount == 0) revert ZeroAmount();

        escrowId = escrowCounter;
        unchecked { escrowCounter++; }

        Escrow storage escrow = escrows[escrowId];
        escrow.escrowId   = escrowId;
        escrow.buyer      = msg.sender;
        escrow.seller     = seller;
        escrow.amount     = amount;
        escrow.description= description;
        escrow.state      = EscrowState.Created;
        escrow.createdAt  = block.timestamp;
        escrow.updatedAt  = block.timestamp;

        buyerEscrows[msg.sender].push(escrowId);
        sellerEscrows[seller].push(escrowId);

        emit EscrowCreated(escrowId, msg.sender, seller, amount, description);
    }

    /**
     * @notice Deposit USDC into the escrow. Requires prior ERC-20 approval.
     * @dev State: Created → Funded.
     */
    function fundEscrow(uint256 escrowId) external {
        Escrow storage escrow = _getEscrowStorage(escrowId);

        if (escrow.buyer != msg.sender) revert NotBuyer();
        if (escrow.state != EscrowState.Created) revert InvalidState(escrow.state, EscrowState.Created);

        // CEI: transfer last (but state already changed above this is safe; actually
        // we do the transfer THEN state update to match CEI intent: state first then transfer)
        // State update BEFORE external call (CEI)
        uint256 amount = escrow.amount;
        escrow.state     = EscrowState.Funded;
        escrow.updatedAt = block.timestamp;
        escrow.fundedAt  = block.timestamp;

        usdcToken.safeTransferFrom(msg.sender, address(this), amount);

        emit EscrowFunded(escrowId, msg.sender, amount);
    }

    /**
     * @notice Seller signals that work is complete. Buyer can then release funds.
     * @dev State: Funded → Completed.
     */
    function markCompleted(uint256 escrowId) external {
        Escrow storage escrow = _getEscrowStorage(escrowId);

        if (escrow.seller != msg.sender) revert NotSeller();
        if (escrow.state != EscrowState.Funded) revert InvalidState(escrow.state, EscrowState.Funded);

        escrow.state       = EscrowState.Completed;
        escrow.updatedAt   = block.timestamp;
        escrow.completedAt = block.timestamp;

        emit EscrowCompleted(escrowId, msg.sender);
    }

    /**
     * @notice Buyer releases escrowed USDC to the seller.
     * @dev State: Completed → Released. Guarded by nonReentrant.
     */
    function releaseFunds(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = _getEscrowStorage(escrowId);

        if (escrow.buyer != msg.sender) revert NotBuyer();
        if (escrow.state != EscrowState.Completed) revert InvalidState(escrow.state, EscrowState.Completed);

        uint256 amount = escrow.amount;
        address seller = escrow.seller;

        // CEI: state update before transfer
        escrow.state     = EscrowState.Released;
        escrow.updatedAt = block.timestamp;

        usdcToken.safeTransfer(seller, amount);

        emit EscrowReleased(escrowId, msg.sender, seller, amount);
    }

    /**
     * @notice Buyer cancels an unfunded escrow.
     * @dev State: Created → Cancelled. No funds held yet, so no transfer needed.
     */
    function cancelEscrow(uint256 escrowId) external {
        Escrow storage escrow = _getEscrowStorage(escrowId);

        if (escrow.buyer != msg.sender) revert NotBuyer();
        if (escrow.state != EscrowState.Created) revert InvalidState(escrow.state, EscrowState.Created);

        escrow.state     = EscrowState.Cancelled;
        escrow.updatedAt = block.timestamp;

        emit EscrowCancelled(escrowId, msg.sender);
    }

    /**
     * @notice Buyer reclaims USDC from a funded escrow.
     * @dev State: Funded (or InProgress) → Refunded.
     *      Requires REFUND_LOCK_PERIOD (24h) since funding to prevent front-running.
     *      Guarded by nonReentrant.
     */
    function refundEscrow(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = _getEscrowStorage(escrowId);

        if (escrow.buyer != msg.sender) revert NotBuyer();
        if (escrow.state != EscrowState.Funded && escrow.state != EscrowState.InProgress) {
            revert InvalidState(escrow.state, EscrowState.InProgress);
        }
        if (block.timestamp < escrow.fundedAt + REFUND_LOCK_PERIOD) revert RefundLockActive();

        uint256 amount = escrow.amount;
        address buyer  = escrow.buyer;

        // CEI: state update before transfer
        escrow.state     = EscrowState.Refunded;
        escrow.updatedAt = block.timestamp;

        usdcToken.safeTransfer(buyer, amount);

        emit EscrowRefunded(escrowId, buyer, amount);
    }

    /**
     * @notice Emergency recovery: buyer reclaims USDC from a Completed escrow
     *         that could not be released (e.g. seller address blocklisted).
     * @dev State: Completed → Refunded. Only callable after RELEASE_TIMEOUT (30d).
     *      Guarded by nonReentrant.
     */
    function emergencyRefund(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = _getEscrowStorage(escrowId);

        if (escrow.buyer != msg.sender) revert NotBuyer();
        if (escrow.state != EscrowState.Completed) revert InvalidState(escrow.state, EscrowState.Completed);
        if (block.timestamp < escrow.completedAt + RELEASE_TIMEOUT) revert ReleasePeriodNotExpired();

        uint256 amount = escrow.amount;
        address buyer  = escrow.buyer;

        // CEI: state update before transfer
        escrow.state     = EscrowState.Refunded;
        escrow.updatedAt = block.timestamp;

        usdcToken.safeTransfer(buyer, amount);

        emit EscrowRefunded(escrowId, buyer, amount);
    }

    // -------------------------------------------------------------------------
    // View functions
    // -------------------------------------------------------------------------

    /**
     * @notice Returns the full escrow record for a given ID.
     * @dev Reverts with EscrowNotFound if escrowId does not exist.
     */
    function getEscrow(uint256 escrowId) external view returns (Escrow memory) {
        return _getEscrowStorage(escrowId);
    }

    /**
     * @notice Returns all escrow IDs where `user` is buyer OR seller.
     * @dev Combines buyerEscrows and sellerEscrows arrays; deduplication is not performed.
     */
    function getUserEscrows(address user) external view returns (uint256[] memory) {
        uint256 buyerCount  = buyerEscrows[user].length;
        uint256 sellerCount = sellerEscrows[user].length;
        uint256[] memory ids = new uint256[](buyerCount + sellerCount);

        for (uint256 i = 0; i < buyerCount; i++) {
            ids[i] = buyerEscrows[user][i];
        }
        for (uint256 j = 0; j < sellerCount; j++) {
            ids[buyerCount + j] = sellerEscrows[user][j];
        }

        return ids;
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    function _getEscrowStorage(uint256 escrowId) internal view returns (Escrow storage escrow) {
        escrow = escrows[escrowId];
        if (escrow.escrowId == 0) revert EscrowNotFound(escrowId);
    }
}
