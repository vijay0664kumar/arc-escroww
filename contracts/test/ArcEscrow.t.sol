// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {ArcEscrow} from "../ArcEscrow.sol";

// ---------------------------------------------------------------------------
// Minimal MockERC20 — only the surface ArcEscrow actually calls.
// ---------------------------------------------------------------------------
contract MockERC20 {
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;

    mapping(address => uint256)                      public balanceOf;
    mapping(address => mapping(address => uint256))  public allowance;

    event Transfer(address indexed from, address indexed to,    uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _dec) {
        name     = _name;
        symbol   = _symbol;
        decimals = _dec;
    }

    function mint(address to, uint256 amount) external {
        totalSupply       += amount;
        balanceOf[to]     += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "ERC20: insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to]         += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from]                  >= amount, "ERC20: insufficient balance");
        require(allowance[from][msg.sender]      >= amount, "ERC20: insufficient allowance");
        allowance[from][msg.sender]              -= amount;
        balanceOf[from]                          -= amount;
        balanceOf[to]                            += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

// ---------------------------------------------------------------------------
// Main test contract
// ---------------------------------------------------------------------------
contract ArcEscrowTest is Test {

    // -----------------------------------------------------------------------
    // Mirror the events from ArcEscrow so we can use vm.expectEmit
    // (Solidity 0.8.20 does not allow `emit ContractName.EventName(...)`)
    // -----------------------------------------------------------------------
    event EscrowCreated(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        string  description
    );
    event EscrowFunded(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event EscrowCompleted(uint256 indexed escrowId, address indexed seller);
    event EscrowReleased(
        uint256 indexed escrowId,
        address indexed buyer,
        address indexed seller,
        uint256 amount
    );
    event EscrowRefunded(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event EscrowCancelled(uint256 indexed escrowId, address indexed buyer);

    // -----------------------------------------------------------------------
    // State
    // -----------------------------------------------------------------------
    ArcEscrow  internal arc;
    MockERC20  internal usdc;

    address internal buyer  = makeAddr("buyer");
    address internal seller = makeAddr("seller");
    address internal other  = makeAddr("other");

    uint256 internal constant INITIAL_BALANCE = 100_000e6; // 100 000 USDC (6 dec)
    uint256 internal constant AMOUNT          =   1_000e6; //   1 000 USDC

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    /// Create an escrow as `buyer` and return its ID.
    function _create(uint256 amount) internal returns (uint256 id) {
        vm.prank(buyer);
        id = arc.createEscrow(seller, amount, "test description");
    }

    /// Create + fund an escrow; returns its ID.
    function _createAndFund(uint256 amount) internal returns (uint256 id) {
        id = _create(amount);
        vm.prank(buyer);
        arc.fundEscrow(id);
    }

    /// Create + fund + markCompleted; returns its ID.
    function _createFundComplete(uint256 amount) internal returns (uint256 id) {
        id = _createAndFund(amount);
        vm.prank(seller);
        arc.markCompleted(id);
    }

    // -----------------------------------------------------------------------
    // setUp — fresh state before every test
    // -----------------------------------------------------------------------
    function setUp() public {
        usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        arc  = new ArcEscrow(address(usdc));

        usdc.mint(buyer, INITIAL_BALANCE);
        vm.prank(buyer);
        usdc.approve(address(arc), type(uint256).max);
    }

    // =======================================================================
    // 1. Deployment & initialization
    // =======================================================================

    function test_Constructor_SetsUsdcToken() public view {
        assertEq(address(arc.usdcToken()), address(usdc));
    }

    function test_Constructor_RevertsOnZeroAddress() public {
        vm.expectRevert(ArcEscrow.ZeroAddress.selector);
        new ArcEscrow(address(0));
    }

    function test_Constructor_EscrowCounterStartsAtOne() public view {
        assertEq(arc.escrowCounter(), 1);
    }

    // =======================================================================
    // 2. createEscrow — happy path & reverts
    // =======================================================================

    function test_CreateEscrow_HappyPath() public {
        vm.prank(buyer);
        uint256 id = arc.createEscrow(seller, AMOUNT, "hello");

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(e.escrowId,    id);
        assertEq(e.buyer,       buyer);
        assertEq(e.seller,      seller);
        assertEq(e.amount,      AMOUNT);
        assertEq(e.description, "hello");
        assertEq(uint8(e.state),  uint8(ArcEscrow.EscrowState.Created));
        assertGt(e.createdAt,   0);
        assertEq(e.completedAt, 0);
    }

    function test_CreateEscrow_IncrementsCounter() public {
        uint256 before = arc.escrowCounter();
        _create(AMOUNT);
        assertEq(arc.escrowCounter(), before + 1);
    }

    function test_CreateEscrow_RevertZeroAddressSeller() public {
        vm.prank(buyer);
        vm.expectRevert(ArcEscrow.ZeroAddress.selector);
        arc.createEscrow(address(0), AMOUNT, "desc");
    }

    function test_CreateEscrow_RevertSellerIsBuyer() public {
        vm.prank(buyer);
        vm.expectRevert(ArcEscrow.InvalidSeller.selector);
        arc.createEscrow(buyer, AMOUNT, "desc");
    }

    function test_CreateEscrow_RevertZeroAmount() public {
        vm.prank(buyer);
        vm.expectRevert(ArcEscrow.ZeroAmount.selector);
        arc.createEscrow(seller, 0, "desc");
    }

    function test_CreateEscrow_EmitsEvent() public {
        vm.prank(buyer);
        vm.expectEmit(true, true, true, true, address(arc));
        emit EscrowCreated(1, buyer, seller, AMOUNT, "desc");
        arc.createEscrow(seller, AMOUNT, "desc");
    }

    // =======================================================================
    // 3. fundEscrow — happy path & reverts
    // =======================================================================

    function test_FundEscrow_HappyPath() public {
        uint256 id = _create(AMOUNT);

        uint256 buyerBefore    = usdc.balanceOf(buyer);
        uint256 contractBefore = usdc.balanceOf(address(arc));
        uint256 fundTime       = block.timestamp;

        vm.prank(buyer);
        arc.fundEscrow(id);

        assertEq(usdc.balanceOf(buyer),        buyerBefore    - AMOUNT);
        assertEq(usdc.balanceOf(address(arc)), contractBefore + AMOUNT);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(uint8(e.state), uint8(ArcEscrow.EscrowState.Funded));
        assertEq(e.fundedAt, fundTime);
    }

    function test_FundEscrow_SetsFundedAt() public {
        uint256 id = _create(AMOUNT);

        vm.warp(block.timestamp + 500); // advance time to a distinct value
        uint256 expectedFundedAt = block.timestamp;

        vm.prank(buyer);
        arc.fundEscrow(id);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(e.fundedAt, expectedFundedAt);
    }

    function test_FundEscrow_EmitsEvent() public {
        uint256 id = _create(AMOUNT);

        vm.prank(buyer);
        vm.expectEmit(true, true, false, true, address(arc));
        emit EscrowFunded(id, buyer, AMOUNT);
        arc.fundEscrow(id);
    }

    function test_FundEscrow_RevertNonBuyer() public {
        uint256 id = _create(AMOUNT);

        vm.prank(other);
        vm.expectRevert(ArcEscrow.NotBuyer.selector);
        arc.fundEscrow(id);
    }

    function test_FundEscrow_RevertAlreadyFunded() public {
        uint256 id = _createAndFund(AMOUNT);

        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                ArcEscrow.InvalidState.selector,
                ArcEscrow.EscrowState.Funded,
                ArcEscrow.EscrowState.Created
            )
        );
        arc.fundEscrow(id);
    }

    // =======================================================================
    // 4. markCompleted — happy path & reverts
    // =======================================================================

    function test_MarkCompleted_HappyPath() public {
        uint256 id = _createAndFund(AMOUNT);

        vm.prank(seller);
        arc.markCompleted(id);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(uint8(e.state), uint8(ArcEscrow.EscrowState.Completed));
        assertGt(e.completedAt, 0);
    }

    function test_MarkCompleted_EmitsEvent() public {
        uint256 id = _createAndFund(AMOUNT);

        vm.prank(seller);
        vm.expectEmit(true, true, false, false, address(arc));
        emit EscrowCompleted(id, seller);
        arc.markCompleted(id);
    }

    function test_MarkCompleted_RevertNonSeller() public {
        uint256 id = _createAndFund(AMOUNT);

        vm.prank(other);
        vm.expectRevert(ArcEscrow.NotSeller.selector);
        arc.markCompleted(id);
    }

    function test_MarkCompleted_RevertWrongState() public {
        // State is Created, not Funded
        uint256 id = _create(AMOUNT);

        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                ArcEscrow.InvalidState.selector,
                ArcEscrow.EscrowState.Created,
                ArcEscrow.EscrowState.Funded
            )
        );
        arc.markCompleted(id);
    }

    // =======================================================================
    // 5. releaseFunds — happy path & reverts
    // =======================================================================

    function test_ReleaseFunds_HappyPath() public {
        uint256 id = _createFundComplete(AMOUNT);

        uint256 sellerBefore   = usdc.balanceOf(seller);
        uint256 contractBefore = usdc.balanceOf(address(arc));

        vm.prank(buyer);
        arc.releaseFunds(id);

        assertEq(usdc.balanceOf(seller),       sellerBefore   + AMOUNT);
        assertEq(usdc.balanceOf(address(arc)), contractBefore - AMOUNT);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(uint8(e.state), uint8(ArcEscrow.EscrowState.Released));
    }

    function test_ReleaseFunds_EmitsEvent() public {
        uint256 id = _createFundComplete(AMOUNT);

        vm.prank(buyer);
        vm.expectEmit(true, true, true, true, address(arc));
        emit EscrowReleased(id, buyer, seller, AMOUNT);
        arc.releaseFunds(id);
    }

    function test_ReleaseFunds_RevertNonBuyer() public {
        uint256 id = _createFundComplete(AMOUNT);

        vm.prank(other);
        vm.expectRevert(ArcEscrow.NotBuyer.selector);
        arc.releaseFunds(id);
    }

    function test_ReleaseFunds_RevertDoubleClaim() public {
        uint256 id = _createFundComplete(AMOUNT);

        vm.prank(buyer);
        arc.releaseFunds(id);

        // Second attempt: state is now Released
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                ArcEscrow.InvalidState.selector,
                ArcEscrow.EscrowState.Released,
                ArcEscrow.EscrowState.Completed
            )
        );
        arc.releaseFunds(id);
    }

    function test_ReleaseFunds_RevertRefundAfterRelease() public {
        uint256 id = _createFundComplete(AMOUNT);

        vm.prank(buyer);
        arc.releaseFunds(id);

        // Try to refund — state is Released, not Funded/InProgress
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                ArcEscrow.InvalidState.selector,
                ArcEscrow.EscrowState.Released,
                ArcEscrow.EscrowState.InProgress
            )
        );
        arc.refundEscrow(id);
    }

    // =======================================================================
    // 6. cancelEscrow — happy path & reverts
    // =======================================================================

    function test_CancelEscrow_HappyPath() public {
        uint256 id = _create(AMOUNT);

        vm.prank(buyer);
        arc.cancelEscrow(id);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(uint8(e.state), uint8(ArcEscrow.EscrowState.Cancelled));
    }

    function test_CancelEscrow_EmitsEvent() public {
        uint256 id = _create(AMOUNT);

        vm.prank(buyer);
        vm.expectEmit(true, true, false, false, address(arc));
        emit EscrowCancelled(id, buyer);
        arc.cancelEscrow(id);
    }

    function test_CancelEscrow_RevertNonBuyer() public {
        uint256 id = _create(AMOUNT);

        vm.prank(other);
        vm.expectRevert(ArcEscrow.NotBuyer.selector);
        arc.cancelEscrow(id);
    }

    function test_CancelEscrow_RevertWhenFunded() public {
        uint256 id = _createAndFund(AMOUNT);

        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                ArcEscrow.InvalidState.selector,
                ArcEscrow.EscrowState.Funded,
                ArcEscrow.EscrowState.Created
            )
        );
        arc.cancelEscrow(id);
    }

    // =======================================================================
    // 7. refundEscrow — happy path & reverts
    // =======================================================================

    function test_RefundEscrow_HappyPath() public {
        uint256 id = _createAndFund(AMOUNT);

        // Warp past the 24-hour refund lock period
        vm.warp(block.timestamp + 25 hours);

        uint256 buyerBefore    = usdc.balanceOf(buyer);
        uint256 contractBefore = usdc.balanceOf(address(arc));

        vm.prank(buyer);
        arc.refundEscrow(id);

        assertEq(usdc.balanceOf(buyer),        buyerBefore    + AMOUNT);
        assertEq(usdc.balanceOf(address(arc)), contractBefore - AMOUNT);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(uint8(e.state), uint8(ArcEscrow.EscrowState.Refunded));
    }

    function test_RefundEscrow_EmitsEvent() public {
        uint256 id = _createAndFund(AMOUNT);

        // Warp past the 24-hour refund lock period
        vm.warp(block.timestamp + 25 hours);

        vm.prank(buyer);
        vm.expectEmit(true, true, false, true, address(arc));
        emit EscrowRefunded(id, buyer, AMOUNT);
        arc.refundEscrow(id);
    }

    function test_RefundEscrow_RevertNonBuyer() public {
        uint256 id = _createAndFund(AMOUNT);

        // NotBuyer fires before the time check — no warp needed
        vm.prank(other);
        vm.expectRevert(ArcEscrow.NotBuyer.selector);
        arc.refundEscrow(id);
    }

    function test_RefundEscrow_RevertWrongState_Created() public {
        uint256 id = _create(AMOUNT);

        // InvalidState fires before the time check — no warp needed
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                ArcEscrow.InvalidState.selector,
                ArcEscrow.EscrowState.Created,
                ArcEscrow.EscrowState.InProgress
            )
        );
        arc.refundEscrow(id);
    }

    function test_RefundEscrow_RevertRefundLockActive_1Hour() public {
        uint256 id = _createAndFund(AMOUNT);

        // Warp only 1 hour — still within the 24-hour lock window
        vm.warp(block.timestamp + 1 hours);

        vm.prank(buyer);
        vm.expectRevert(ArcEscrow.RefundLockActive.selector);
        arc.refundEscrow(id);
    }

    // Exactly at fundedAt + REFUND_LOCK_PERIOD the lock is lifted and the call succeeds.
    function test_RefundEscrow_SucceedsAtExact24HourBoundary() public {
        uint256 id = _createAndFund(AMOUNT);
        ArcEscrow.Escrow memory e = arc.getEscrow(id);

        // Warp to exactly fundedAt + 24 hours (the intended boundary)
        vm.warp(e.fundedAt + 24 hours);

        uint256 buyerBefore = usdc.balanceOf(buyer);

        vm.prank(buyer);
        arc.refundEscrow(id);

        assertEq(usdc.balanceOf(buyer), buyerBefore + AMOUNT);
        ArcEscrow.Escrow memory e2 = arc.getEscrow(id);
        assertEq(uint8(e2.state), uint8(ArcEscrow.EscrowState.Refunded));
    }

    // =======================================================================
    // 8. emergencyRefund — happy path & reverts
    // =======================================================================

    function test_EmergencyRefund_HappyPath() public {
        uint256 id = _createFundComplete(AMOUNT);

        vm.warp(block.timestamp + arc.RELEASE_TIMEOUT() + 1);

        uint256 buyerBefore = usdc.balanceOf(buyer);

        vm.prank(buyer);
        arc.emergencyRefund(id);

        assertEq(usdc.balanceOf(buyer), buyerBefore + AMOUNT);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(uint8(e.state), uint8(ArcEscrow.EscrowState.Refunded));
    }

    function test_EmergencyRefund_EmitsEvent() public {
        uint256 id = _createFundComplete(AMOUNT);
        vm.warp(block.timestamp + arc.RELEASE_TIMEOUT() + 1);

        vm.prank(buyer);
        vm.expectEmit(true, true, false, true, address(arc));
        emit EscrowRefunded(id, buyer, AMOUNT);
        arc.emergencyRefund(id);
    }

    function test_EmergencyRefund_RevertBeforeTimeout_1Day() public {
        uint256 id = _createFundComplete(AMOUNT);

        vm.warp(block.timestamp + 1 days);

        vm.prank(buyer);
        vm.expectRevert(ArcEscrow.ReleasePeriodNotExpired.selector);
        arc.emergencyRefund(id);
    }

    function test_EmergencyRefund_RevertAtExactBoundary() public {
        uint256 id = _createFundComplete(AMOUNT);
        ArcEscrow.Escrow memory e = arc.getEscrow(id);

        // One second before expiry is still too early
        vm.warp(e.completedAt + arc.RELEASE_TIMEOUT() - 1);

        vm.prank(buyer);
        vm.expectRevert(ArcEscrow.ReleasePeriodNotExpired.selector);
        arc.emergencyRefund(id);
    }

    function test_EmergencyRefund_RevertNonBuyer() public {
        uint256 id = _createFundComplete(AMOUNT);
        vm.warp(block.timestamp + arc.RELEASE_TIMEOUT() + 1);

        vm.prank(other);
        vm.expectRevert(ArcEscrow.NotBuyer.selector);
        arc.emergencyRefund(id);
    }

    function test_EmergencyRefund_RevertWrongState_Funded() public {
        uint256 id = _createAndFund(AMOUNT);
        vm.warp(block.timestamp + arc.RELEASE_TIMEOUT() + 1);

        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                ArcEscrow.InvalidState.selector,
                ArcEscrow.EscrowState.Funded,
                ArcEscrow.EscrowState.Completed
            )
        );
        arc.emergencyRefund(id);
    }

    // =======================================================================
    // 9. Full end-to-end flows
    // =======================================================================

    function test_FullFlow_CreateFundCompleteRelease() public {
        vm.prank(buyer);
        uint256 id = arc.createEscrow(seller, AMOUNT, "full flow");
        assertEq(uint8(arc.getEscrow(id).state), uint8(ArcEscrow.EscrowState.Created));

        vm.prank(buyer);
        arc.fundEscrow(id);
        assertEq(uint8(arc.getEscrow(id).state), uint8(ArcEscrow.EscrowState.Funded));

        vm.prank(seller);
        arc.markCompleted(id);
        assertEq(uint8(arc.getEscrow(id).state), uint8(ArcEscrow.EscrowState.Completed));

        uint256 sellerBefore = usdc.balanceOf(seller);
        vm.prank(buyer);
        arc.releaseFunds(id);
        assertEq(uint8(arc.getEscrow(id).state), uint8(ArcEscrow.EscrowState.Released));
        assertEq(usdc.balanceOf(seller), sellerBefore + AMOUNT);
    }

    function test_FullFlow_CreateCancel() public {
        uint256 id = _create(AMOUNT);
        vm.prank(buyer);
        arc.cancelEscrow(id);
        assertEq(uint8(arc.getEscrow(id).state), uint8(ArcEscrow.EscrowState.Cancelled));
    }

    function test_FullFlow_CreateFundRefund() public {
        uint256 id = _createAndFund(AMOUNT);

        // Warp past the 24-hour refund lock period
        vm.warp(block.timestamp + 25 hours);

        uint256 buyerBefore = usdc.balanceOf(buyer);

        vm.prank(buyer);
        arc.refundEscrow(id);

        assertEq(uint8(arc.getEscrow(id).state), uint8(ArcEscrow.EscrowState.Refunded));
        assertEq(usdc.balanceOf(buyer), buyerBefore + AMOUNT);
    }

    function test_FullFlow_EmergencyRefund() public {
        uint256 id = _createFundComplete(AMOUNT);
        vm.warp(block.timestamp + arc.RELEASE_TIMEOUT() + 1);

        uint256 buyerBefore = usdc.balanceOf(buyer);
        vm.prank(buyer);
        arc.emergencyRefund(id);

        assertEq(uint8(arc.getEscrow(id).state), uint8(ArcEscrow.EscrowState.Refunded));
        assertEq(usdc.balanceOf(buyer), buyerBefore + AMOUNT);
    }

    // =======================================================================
    // 10. getEscrow — not-found revert
    // =======================================================================

    function test_GetEscrow_RevertNotFound() public {
        vm.expectRevert(
            abi.encodeWithSelector(ArcEscrow.EscrowNotFound.selector, 999)
        );
        arc.getEscrow(999);
    }

    // =======================================================================
    // 11. getUserEscrows
    // =======================================================================

    function test_GetUserEscrows_BuyerAndSellerCombined() public {
        uint256 id1 = _create(AMOUNT);
        uint256 id2 = _create(AMOUNT * 2);

        // A third address creates an escrow with `buyer` as the seller
        address other2 = makeAddr("other2");
        usdc.mint(other2, INITIAL_BALANCE);
        vm.prank(other2);
        usdc.approve(address(arc), type(uint256).max);
        vm.prank(other2);
        uint256 id3 = arc.createEscrow(buyer, AMOUNT, "buyer as seller");

        uint256[] memory ids = arc.getUserEscrows(buyer);
        assertEq(ids.length, 3);
        assertEq(ids[0], id1);
        assertEq(ids[1], id2);
        assertEq(ids[2], id3);
    }

    function test_GetUserEscrows_EmptyForNewAddress() public view {
        uint256[] memory ids = arc.getUserEscrows(other);
        assertEq(ids.length, 0);
    }

    function test_GetUserEscrows_OnlyAsSeller() public {
        uint256 id1 = _create(AMOUNT);

        uint256[] memory ids = arc.getUserEscrows(seller);
        assertEq(ids.length, 1);
        assertEq(ids[0], id1);
    }

    // =======================================================================
    // 12. Reentrancy — nonReentrant guard + CEI pattern verification
    //     We confirm state is flipped before the token transfer, so a second
    //     call (simulating re-entry) hits InvalidState rather than draining.
    // =======================================================================

    function test_Reentrancy_ReleaseFunds_StateBeforeTransfer() public {
        uint256 id = _createFundComplete(AMOUNT);

        vm.prank(buyer);
        arc.releaseFunds(id);

        // A re-entrant (or immediate second) call must revert with InvalidState
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                ArcEscrow.InvalidState.selector,
                ArcEscrow.EscrowState.Released,
                ArcEscrow.EscrowState.Completed
            )
        );
        arc.releaseFunds(id);
    }

    function test_Reentrancy_RefundEscrow_StateBeforeTransfer() public {
        uint256 id = _createAndFund(AMOUNT);

        // Warp past the 24-hour lock so the first refund call succeeds
        vm.warp(block.timestamp + 25 hours);

        vm.prank(buyer);
        arc.refundEscrow(id);

        // Second call: state is now Refunded — InvalidState fires before the time check
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                ArcEscrow.InvalidState.selector,
                ArcEscrow.EscrowState.Refunded,
                ArcEscrow.EscrowState.InProgress
            )
        );
        arc.refundEscrow(id);
    }

    // =======================================================================
    // 13. FUZZ: createEscrow with random amounts and sellers
    // =======================================================================

    function testFuzz_CreateEscrow_AmountAndSeller(
        address fuzzSeller,
        uint256 fuzzAmount
    ) public {
        vm.assume(fuzzSeller != address(0));
        vm.assume(fuzzSeller != buyer);
        vm.assume(fuzzAmount > 0);
        vm.assume(fuzzAmount <= type(uint128).max);

        usdc.mint(buyer, fuzzAmount);

        vm.prank(buyer);
        uint256 id = arc.createEscrow(fuzzSeller, fuzzAmount, "fuzz");

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(e.buyer,  buyer);
        assertEq(e.seller, fuzzSeller);
        assertEq(e.amount, fuzzAmount);
        assertEq(uint8(e.state), uint8(ArcEscrow.EscrowState.Created));
    }

    // =======================================================================
    // 14. FUZZ: full happy path with random amounts
    // =======================================================================

    function testFuzz_FullHappyPath(uint256 fuzzAmount) public {
        fuzzAmount = bound(fuzzAmount, 1, INITIAL_BALANCE);

        // Top up buyer if needed
        uint256 current = usdc.balanceOf(buyer);
        if (current < fuzzAmount) {
            usdc.mint(buyer, fuzzAmount - current);
        }

        uint256 sellerBefore = usdc.balanceOf(seller);

        vm.prank(buyer);
        uint256 id = arc.createEscrow(seller, fuzzAmount, "fuzz full");

        vm.prank(buyer);
        arc.fundEscrow(id);

        vm.prank(seller);
        arc.markCompleted(id);

        vm.prank(buyer);
        arc.releaseFunds(id);

        assertEq(uint8(arc.getEscrow(id).state), uint8(ArcEscrow.EscrowState.Released));
        assertEq(usdc.balanceOf(seller), sellerBefore + fuzzAmount);
        assertEq(usdc.balanceOf(address(arc)), 0);
    }

    // =======================================================================
    // 15. FUZZ: emergency refund with variable warp times past the deadline
    // =======================================================================

    function testFuzz_EmergencyRefund_TimeBound(uint256 warpExtra) public {
        warpExtra = bound(warpExtra, 1, 365 days);

        uint256 id = _createFundComplete(AMOUNT);
        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        uint256 deadline = e.completedAt + arc.RELEASE_TIMEOUT();

        vm.warp(deadline + warpExtra);

        uint256 buyerBefore = usdc.balanceOf(buyer);
        vm.prank(buyer);
        arc.emergencyRefund(id);

        assertEq(usdc.balanceOf(buyer), buyerBefore + AMOUNT);
    }

    // =======================================================================
    // 16. RELEASE_TIMEOUT and REFUND_LOCK_PERIOD constant sanity
    // =======================================================================

    function test_ReleaseTimeout_Is30Days() public view {
        assertEq(arc.RELEASE_TIMEOUT(), 30 days);
    }

    function test_RefundLockPeriod_Is86400() public view {
        assertEq(arc.REFUND_LOCK_PERIOD(), 86400); // 24 * 3600
    }

    // =======================================================================
    // 17. Multiple concurrent escrows stay independent
    // =======================================================================

    function test_MultipleEscrows_IndependentState() public {
        uint256 id1 = _createAndFund(AMOUNT);
        uint256 id2 = _create(AMOUNT * 2);

        vm.prank(seller);
        arc.markCompleted(id1);
        vm.prank(buyer);
        arc.releaseFunds(id1);

        // id2 remains in Created state; contract balance is zero (id1 released)
        ArcEscrow.Escrow memory e2 = arc.getEscrow(id2);
        assertEq(uint8(e2.state), uint8(ArcEscrow.EscrowState.Created));
        assertEq(usdc.balanceOf(address(arc)), 0);
    }

    // =======================================================================
    // 18. updatedAt is refreshed on transitions
    // =======================================================================

    function test_UpdatedAt_RefreshedOnFund() public {
        uint256 t0 = block.timestamp;
        uint256 id = _create(AMOUNT);

        vm.warp(t0 + 100);
        vm.prank(buyer);
        arc.fundEscrow(id);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(e.updatedAt, t0 + 100);
    }

    function test_UpdatedAt_RefreshedOnComplete() public {
        uint256 id = _createAndFund(AMOUNT);

        vm.warp(block.timestamp + 200);
        uint256 ts = block.timestamp;
        vm.prank(seller);
        arc.markCompleted(id);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(e.updatedAt,   ts);
        assertEq(e.completedAt, ts);
    }

    function test_UpdatedAt_RefreshedOnRelease() public {
        uint256 id = _createFundComplete(AMOUNT);

        vm.warp(block.timestamp + 500);
        uint256 ts = block.timestamp;
        vm.prank(buyer);
        arc.releaseFunds(id);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(e.updatedAt, ts);
    }

    function test_UpdatedAt_RefreshedOnCancel() public {
        uint256 id = _create(AMOUNT);

        vm.warp(block.timestamp + 42);
        uint256 ts = block.timestamp;
        vm.prank(buyer);
        arc.cancelEscrow(id);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(e.updatedAt, ts);
    }

    function test_UpdatedAt_RefreshedOnRefund() public {
        uint256 id = _createAndFund(AMOUNT);

        // Warp past the 24-hour lock (+ a small offset so updatedAt is distinct)
        vm.warp(block.timestamp + 25 hours + 77);
        uint256 ts = block.timestamp;
        vm.prank(buyer);
        arc.refundEscrow(id);

        ArcEscrow.Escrow memory e = arc.getEscrow(id);
        assertEq(e.updatedAt, ts);
    }

    // =======================================================================
    // 19. Public mapping accessors
    // =======================================================================

    function test_BuyerEscrowsMapping() public {
        uint256 id1 = _create(AMOUNT);
        uint256 id2 = _create(AMOUNT);

        assertEq(arc.buyerEscrows(buyer, 0), id1);
        assertEq(arc.buyerEscrows(buyer, 1), id2);
    }

    function test_SellerEscrowsMapping() public {
        uint256 id1 = _create(AMOUNT);
        uint256 id2 = _create(AMOUNT * 3);

        assertEq(arc.sellerEscrows(seller, 0), id1);
        assertEq(arc.sellerEscrows(seller, 1), id2);
    }

    // =======================================================================
    // 20. Escrow IDs are sequential starting from 1
    // =======================================================================

    function test_EscrowIds_Sequential() public {
        uint256 id1 = _create(AMOUNT);
        uint256 id2 = _create(AMOUNT);
        uint256 id3 = _create(AMOUNT);

        assertEq(id1, 1);
        assertEq(id2, 2);
        assertEq(id3, 3);
        assertEq(arc.escrowCounter(), 4);
    }

    // =======================================================================
    // 21. Seller cannot fund or release — only buyer can
    // =======================================================================

    function test_SellerCannotFund() public {
        uint256 id = _create(AMOUNT);

        vm.prank(seller);
        vm.expectRevert(ArcEscrow.NotBuyer.selector);
        arc.fundEscrow(id);
    }

    function test_SellerCannotRelease() public {
        uint256 id = _createFundComplete(AMOUNT);

        vm.prank(seller);
        vm.expectRevert(ArcEscrow.NotBuyer.selector);
        arc.releaseFunds(id);
    }

    function test_SellerCannotRefund() public {
        uint256 id = _createAndFund(AMOUNT);

        vm.prank(seller);
        vm.expectRevert(ArcEscrow.NotBuyer.selector);
        arc.refundEscrow(id);
    }

    function test_SellerCannotCancel() public {
        uint256 id = _create(AMOUNT);

        vm.prank(seller);
        vm.expectRevert(ArcEscrow.NotBuyer.selector);
        arc.cancelEscrow(id);
    }

    // =======================================================================
    // 22. Buyer cannot markCompleted
    // =======================================================================

    function test_BuyerCannotMarkCompleted() public {
        uint256 id = _createAndFund(AMOUNT);

        vm.prank(buyer);
        vm.expectRevert(ArcEscrow.NotSeller.selector);
        arc.markCompleted(id);
    }

    // =======================================================================
    // 23. Token balance conservation across escrow lifecycle
    // =======================================================================

    function test_TokenBalance_ConservationAfterRelease() public {
        uint256 buyerStart  = usdc.balanceOf(buyer);
        uint256 sellerStart = usdc.balanceOf(seller);

        uint256 id = _createFundComplete(AMOUNT);

        // During Completed state the contract holds AMOUNT
        assertEq(usdc.balanceOf(address(arc)), AMOUNT);

        vm.prank(buyer);
        arc.releaseFunds(id);

        // After release: buyer lost AMOUNT, seller gained AMOUNT, contract zero
        assertEq(usdc.balanceOf(buyer),        buyerStart  - AMOUNT);
        assertEq(usdc.balanceOf(seller),       sellerStart + AMOUNT);
        assertEq(usdc.balanceOf(address(arc)), 0);
    }

    function test_TokenBalance_ConservationAfterRefund() public {
        uint256 buyerStart = usdc.balanceOf(buyer);

        uint256 id = _createAndFund(AMOUNT);
        assertEq(usdc.balanceOf(address(arc)), AMOUNT);

        // Warp past the 24-hour refund lock period
        vm.warp(block.timestamp + 25 hours);

        vm.prank(buyer);
        arc.refundEscrow(id);

        // After refund: buyer's balance fully restored, contract zero
        assertEq(usdc.balanceOf(buyer),        buyerStart);
        assertEq(usdc.balanceOf(address(arc)), 0);
    }
}
