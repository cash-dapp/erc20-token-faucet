// SPDX-License-Identifier: MIT

/////////////////////////////////////////////////////////////////////////////////////
//     _______  _______  _______  __   __   ______   _______  _______  _______     //
//    |       ||   _   ||       ||  | |  | |      | |   _   ||       ||       |    //
//    |       ||  |_|  ||  _____||  |_|  | |  _    ||  |_|  ||    _  ||    _  |    //
//    |       ||       || |_____ |       | | | |   ||       ||   |_| ||   |_| |    //
//    |      _||       ||_____  ||       | | |_|   ||       ||    ___||    ___|    //
//    |     |_ |   _   | _____| ||   _   | |       ||   _   ||   |    |   |        //
//    |_______||__| |__||_______||__| |__| |______| |__| |__||___|    |___|        //
//                                                          x.com/hellocashdapp    //
/////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.0;

/**
 * @title ERC20 Faucet
 * @dev A simple and flexible ERC20 token faucet with optional referral bonuses.
 *
 * @notice This contract allows users to claim a specified amount of ERC20 tokens at regular intervals.
 *         The faucet can be managed by an owner who can adjust claim parameters, deposit/withdraw tokens,
 *         pause/unpause the faucet, blacklist addresses, and initiate claims for specific addresses.
 *
 * @dev Warning:
 * - Deploy this contract with caution, as it involves financial transactions and user interactions.
 * - Carefully review and test all parameters and functionalities before deployment.
 * - Consider security audits and best practices to safeguard the contract and user funds.
 * - Use at your own risk!
 *
 * @author jp0d
 * x.com/hellocashdapp
 *
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC20Faucet is Ownable {
    IERC20 public token;
    uint256 public claimAmount;
    uint256 public claimFrequency;
    uint256 public referralBonusPercentage;
    bool public isPaused;

    /**
     * @notice User Claim Data Structure
     * @dev Defines a structure to store data related to user claims, including the last claim timestamp,
     *      blacklisting status, and the address of the referrer (if any).
     */
    struct UserClaimData {
        uint256 lastClaimTimestamp; // Timestamp of the user's last claim
        bool isBlacklisted; // Flag indicating whether the user's address is blacklisted
        address referrer; // Referrer's address
        uint256 totalTokensClaimed; // Total tokens claimed by the user
        uint256 totalClaimsMade; // Total number of claims made by the user
        uint256 totalReferralClaims; // Total number of claims made using a referral
    }

    /**
     * @notice User Claim Data Mapping
     * @dev Maps user addresses to their corresponding claim data using the UserClaimData structure.
     */
    mapping(address => UserClaimData) public userClaimData;

    /**
     * @notice Referrer Mapping
     * @dev Maps user addresses to their referrers' addresses.
     */
    mapping(address => address) public referrers;

    /**
     * @notice Tokens Claimed Event
     * @dev Emitted when a user successfully claims tokens from the faucet, providing information
     *      about the user and the claimed amount.
     */
    event TokensClaimed(
        address indexed user,
        uint256 amount,
        address indexed referrer,
        uint256 totalTokensClaimed,
        uint256 totalClaimsMade,
        uint256 totalReferralClaims
    );

    /**
     * @notice Pause Status Event
     * @dev Emitted when the owner toggles the pause status of the faucet, indicating whether
     *      user claims are currently paused or active.
     */
    event PauseStatus(bool isPaused);

    /**
     * @notice Not Paused Modifier
     * @dev Ensures that the faucet is not paused before allowing the execution of a function.
     */
    modifier notPaused() {
        require(!isPaused, "Faucet is paused");
        _;
    }

    /**
     * @notice Not Blacklisted Modifier
     * @dev Ensures that the caller's address is not blacklisted before allowing the execution of a function.
     */
    modifier notBlacklisted() {
        require(
            !userClaimData[msg.sender].isBlacklisted,
            "Address is blacklisted"
        );
        _;
    }

    /**
     * @notice Can Claim Modifier
     * @dev Ensures that the caller is eligible to make a claim based on claim frequency and timing constraints.
     */
    modifier canClaim() {
        require(
            claimFrequency > 0,
            "Claim frequency must be greater than zero"
        );
        require(
            block.timestamp >=
                userClaimData[msg.sender].lastClaimTimestamp + claimFrequency,
            "Claim frequency not reached"
        );
        _;
    }

    /**
     * @notice ERC20 Faucet Constructor
     * @dev Initializes the ERC20 Faucet contract with the specified parameters and sets the initial owner using the Ownable constructor.
     * @param _token The address of the ERC20 token that users can claim from the faucet.
     * @param _claimAmount The amount of tokens a user can claim in each transaction.
     * @param _claimFrequency The time interval a user must wait before making another claim, specified in seconds.
     * @param _owner The initial owner of the faucet contract.
     *
     * @dev It's important to note the following:
     * - `_claimFrequency` is entered in seconds. For example, setting it to 3600 means users must wait one hour between claims.
     * - Ensure that the specified ERC20 token has been approved for use with the faucet contract.
     * - The initial owner should be a secure and trusted address that will have control over faucet parameters and functions.
     * - After deployment, the owner can manage the faucet, deposit tokens, modify parameters, and control the contract's operation.
     * - Users can claim tokens from the faucet by calling the `claimTokens` function, subject to claim frequency and amount limitations.
     * - The contract is initially active, allowing users to claim tokens. The owner can pause the faucet using the `togglePause` function if needed.
     * - Blacklisting addresses using `blacklistAddress` prevents specific addresses from claiming tokens.
     * - The maximum claim amount for each user can be modified by the owner using the `modifyMaxClaimAmount` function.
     * - It's essential to thoroughly test the contract on a testnet before deploying it to the mainnet.
     * - Consider performing security audits or consulting with experts to ensure the robustness of your contract.
     */
    constructor(
        address _token,
        uint256 _claimAmount,
        uint256 _claimFrequency,
        uint256 _referralBonusPercentage,
        address _owner
    ) Ownable(_owner) {
        token = IERC20(_token);
        claimAmount = _claimAmount;
        claimFrequency = _claimFrequency;
        referralBonusPercentage = _referralBonusPercentage;
    }

    /**
     * @notice User Claims Tokens
     * @dev Allows users to claim tokens from the faucet.
     *
     * @dev It's important to note the following:
     * - Users must satisfy the conditions specified by modifiers: notPaused, notBlacklisted, and canClaim.
     * - Updates the last claim timestamp.
     * - Ensures there are sufficient funds in the faucet to cover the claim amount.
     * - Transfers the claimed tokens to the user.
     * - Emits a `TokensClaimed` event to log the successful token claim.
     * - If the claim transaction fails due to insufficient funds, it will revert with the message "Insufficient funds in the faucet."
     * - If the claim transaction fails for any other reason, it will revert with the message "Token transfer failed."
     */
    function claimTokens() external notPaused notBlacklisted canClaim {
        userClaimData[msg.sender].lastClaimTimestamp = block.timestamp;

        require(
            token.balanceOf(address(this)) >= claimAmount,
            "Insufficient funds in the faucet"
        );
        require(
            token.transfer(msg.sender, claimAmount),
            "Token transfer failed"
        );

        // Update user's claim status
        userClaimData[msg.sender].totalTokensClaimed += claimAmount;
        userClaimData[msg.sender].totalClaimsMade += 1;

        emit TokensClaimed(
            msg.sender,
            claimAmount,
            userClaimData[msg.sender].referrer,
            userClaimData[msg.sender].totalTokensClaimed,
            userClaimData[msg.sender].totalClaimsMade,
            userClaimData[msg.sender].totalReferralClaims
        );
    }

    /**
     * @notice User Claims Tokens with Referral
     * @dev Allows users to claim tokens from the faucet with a referral bonus.
     * @param _referrer If set to address(0), no referral bonus is applied.
     *
     * @dev It's important to note the following:
     * - Users must satisfy the conditions specified by modifiers: notPaused, notBlacklisted, and canClaim.
     * - Requires a valid referrer address, which must not be the claimer's own address.
     * - Assigns the referrer, calculates the referral bonus, and transfers tokens to both the user and the referrer.
     * - Updates the last claim timestamp, and emits a `TokensClaimed` event.
     * - If the claim transaction fails due to insufficient funds, it will revert with the message "Insufficient funds in the faucet."
     * - If the claim transaction fails for any other reason, it will revert with the message "Token transfer failed."
     */
    function claimTokensWithReferral(address _referrer)
        external
        notPaused
        notBlacklisted
        canClaim
    {
        // Ensure a valid referrer is provided and it's not the claimer's address
        require(
            _referrer != address(0) && _referrer != msg.sender,
            "Invalid referrer address"
        );

        // Assign the referrer if it's a new referral
        if (referrers[msg.sender] == address(0)) {
            referrers[msg.sender] = _referrer;
        }

        // Calculate referral bonus
        uint256 referralBonus = (claimAmount * referralBonusPercentage) / 100;

        // Transfer tokens to the user
        require(
            token.transfer(msg.sender, claimAmount + referralBonus),
            "Token transfer to user failed"
        );

        // Transfer tokens to the referrer (if valid)
        if (_referrer != address(0)) {
            require(
                token.transfer(_referrer, referralBonus),
                "Token transfer to referrer failed"
            );

            // Update referrer's claim status
            userClaimData[_referrer].totalReferralClaims += 1;
        }

        // Update user's claim status
        userClaimData[msg.sender].lastClaimTimestamp = block.timestamp;
        userClaimData[msg.sender].totalTokensClaimed += claimAmount;
        userClaimData[msg.sender].totalClaimsMade += 1;

        emit TokensClaimed(
            msg.sender,
            claimAmount + referralBonus,
            _referrer,
            userClaimData[msg.sender].totalTokensClaimed,
            userClaimData[msg.sender].totalClaimsMade,
            userClaimData[_referrer].totalReferralClaims
        );
    }

    /**
     * @notice Owner-initiated claim for a specific address
     * @dev Allows the owner to initiate a claim for a specific address without referral benefits.
     * @param _claimer The address for which the owner initiates the claim to.
     */
    function ownerInitiatedClaim(address _claimer)
        external
        onlyOwner
        notPaused
        notBlacklisted
    {
        require(
            _claimer != address(0) && _claimer != msg.sender,
            "Invalid claimer address"
        );

        // Transfer tokens to the claimer
        require(token.transfer(_claimer, claimAmount), "Token transfer failed");
    }

    /**
     * @notice Owner Deposits Tokens
     * @dev Allows the owner to deposit claimable tokens into the faucet.
     * @param amount The amount of tokens to be deposited.
     *
     * @dev It's important to note the following:
     * - Use this function to load the faucet with tokens for users to claim.
     * - If the deposit transaction fails, it will revert with the message "Token deposit failed."
     */
    function depositTokens(uint256 amount) external onlyOwner {
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Token deposit failed"
        );
    }

    /**
     * @notice Owner Modifies Claim Amount
     * @dev Allows the owner to modify the amount of tokens a user can claim per transaction.
     * @param newAmount The new claim amount to be set, specified in the smallest unit of the token (e.g., wei for ETH).
     *
     * @dev It's important to note the following:
     * - Use this function to adjust the token claim amount.
     * - Ensure the `newAmount` parameter is specified in WEI.
     */
    function modifyClaimAmount(uint256 newAmount) external onlyOwner {
        claimAmount = newAmount;
    }

    /**
     * @notice Owner Modifies Claim Frequency
     * @dev Allows the owner to modify the time interval a user must wait before making another claim.
     * @param newFrequency The new claim frequency, specified in seconds, to be set.
     *
     * @dev It's important to note the following:
     * - Use this function to adjust the time interval in seconds, between user claims.
     */
    function modifyClaimFrequency(uint256 newFrequency) external onlyOwner {
        claimFrequency = newFrequency;
    }

    /**
     * @notice Owner Toggles Faucet Pause
     * @dev Allows the owner to pause or resume the faucet, preventing or enabling user claims.
     *
     * @dev It's important to note the following:
     * - Use this function to temporarily halt user claims or re-enable the faucet as needed.
     * - Emits a `PauseStatus` event indicating the current pause status.
     */
    function togglePause() external onlyOwner {
        isPaused = !isPaused;
        emit PauseStatus(isPaused);
    }

    /**
     * @notice Owner Blacklists Address
     * @dev Allows the owner to blacklist a user's address, preventing them from claiming tokens.
     * @param user The address to be blacklisted.
     *
     * @dev It's important to note the following:
     * - Use this function to prevent specific addresses from claiming tokens, enhancing security and control.
     */
    function blacklistAddress(address user) external onlyOwner {
        userClaimData[user].isBlacklisted = true;
    }

    /**
     * @notice Owner Unblacklists Address
     * @dev Allows the owner to remove a user's address from the blacklist, enabling them to claim tokens.
     * @param user The address to be unblacklisted.
     *
     * @dev It's important to note the following:
     * - Use this function to remove addresses from the blacklist, allowing previously blacklisted users to claim tokens.
     */
    function unblacklistAddress(address user) external onlyOwner {
        userClaimData[user].isBlacklisted = false;
    }

    /**
     * @notice Emergency Withdrawal / Owner Withdraws All Funds
     * @dev Allows the owner to withdraw all ETH and ERC-20 tokens from the faucet.
     *
     * @dev It's important to note the following:
     * - Only the owner can call this function.
     * - If the withdrawal transaction fails for any reason, it will revert with the message "Withdrawal failed."
     */
    function withdrawAllFunds() external onlyOwner {
        // Withdraw ETH
        payable(owner()).transfer(address(this).balance);

        // Withdraw ERC-20 tokens
        IERC20 erc20Token = IERC20(token);
        require(
            erc20Token.transfer(owner(), erc20Token.balanceOf(address(this))),
            "Withdrawal failed"
        );
    }

    /**
     * @notice Owner Modifies Referral Bonus Percentage
     * @dev Allows the contract owner to modify the percentage of referral bonus.
     * @param newPercentage The new referral bonus percentage to be set.
     *
     * @dev It's important to note the following:
     * - Use this function to adjust the referral bonus percentage.
     * - This function is restricted to be called only by the owner of the contract using the onlyOwner modifier.
     */
    function modifyReferralBonusPercentage(uint256 newPercentage)
        external
        onlyOwner
    {
        referralBonusPercentage = newPercentage;
    }

    /**
     * @notice Get Total Tokens Claimed by a User
     * @dev Retrieves the total number of tokens claimed by a specific user.
     * @param user The address of the user for whom the total tokens claimed is queried.
     * @return The total number of tokens claimed by the specified user.
     * - This is a read-only function that does not affect the state of the contract.
     */
    function getTotalTokensClaimed(address user)
        external
        view
        returns (uint256)
    {
        return userClaimData[user].totalTokensClaimed;
    }

    /**
     * @notice Get Total Claims Made by a User
     * @dev Retrieves the total number of claims made by a specific user.
     * @param user The address of the user for whom the total claims made is queried.
     * @return The total number of claims made by the specified user.
     * - This is a read-only function that does not affect the state of the contract.
     */
    function getTotalClaimsMade(address user) external view returns (uint256) {
        return userClaimData[user].totalClaimsMade;
    }

    /**
     * @notice Get Total Referral Claims by a User
     * @dev Retrieves the total number of referral claims made by a specific user.
     * @param user The address of the user for whom the total referral claims is queried.
     * @return The total number of referral claims made by the specified user.
     * - This is a read-only function that does not affect the state of the contract.
     */
    function getTotalReferralClaims(address user)
        external
        view
        returns (uint256)
    {
        return userClaimData[user].totalReferralClaims;
    }

    /**
     * @notice Get Faucet Token Balance
     * @dev Allows anyone to check the current balance of the ERC20 token held by the faucet.
     * @return The current balance of tokens in the faucet contract.
     *
     * @dev It's important to note the following:
     * - Use this function to verify the current token balance in the faucet before initiating user claims or other operations.
     * - This is a read-only function that does not affect the state of the contract.
     */
    function getFaucetBalance() external view returns (uint256) {
        uint256 balance = token.balanceOf(address(this));

        // Check if the balance is zero and return 0
        if (balance == 0) {
            return 0;
        }

        // Return the actual balance if it's not zero
        return balance;
    }
}
