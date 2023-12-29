# ERC20 Faucet

![HelloCashDApp Logo](https://raw.githubusercontent.com/username/repo/master/hellocashdapp-logo.png)

A simple and flexible ERC20 token faucet with optional referral bonuses.

## Table of Contents

- [Introduction](#introduction)
- [Contract Overview](#contract-overview)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Owner Functions](#owner-functions)
- [Security Considerations](#security-considerations)
- [License](#license)

## Introduction

This ERC20 Faucet is designed to provide users with a straightforward method to claim a specified amount of ERC20 tokens at regular intervals. The faucet is managed by an owner who can adjust claim parameters, deposit/withdraw tokens, pause/unpause the faucet, blacklist addresses, and initiate claims for specific addresses.

**Warning:**
- Deploy this contract with caution, as it involves financial transactions and user interactions.
- Carefully review and test all parameters and functionalities before deployment.
- Consider security audits and best practices to safeguard the contract and user funds.
- Use at your own risk!

## Contract Overview

The contract is structured with the following components:
- **Context (OpenZeppelin):** Provides information about the current execution context.
- **Ownable (OpenZeppelin):** Provides a basic access control mechanism, allowing an owner to manage specific functions.
- **IERC20 (OpenZeppelin):** Interface for the ERC20 standard.
- **ERC20Faucet:** The main faucet contract that implements the functionality of allowing users to claim tokens, referral bonuses, and various owner management functions.

## Getting Started

1. Deploy the contract with the desired ERC20 token, claim amount, claim frequency, referral bonus percentage, and initial owner.
2. Ensure that the specified ERC20 token has been approved for use with the faucet contract.
3. Users can claim tokens by calling the `claimTokens` function, subject to claim frequency and amount limitations.

## Usage

- **claimTokens:** Allows users to claim tokens from the faucet.
- **claimTokensWithReferral:** Allows users to claim tokens with a referral bonus.
- **ownerInitiatedClaim:** Allows the owner to initiate a claim for a specific address without referral benefits.
- **depositTokens:** Allows the owner to deposit claimable tokens into the faucet.
- **modifyClaimAmount:** Allows the owner to modify the amount of tokens a user can claim per transaction.
- **modifyClaimFrequency:** Allows the owner to modify the time interval a user must wait before making another claim.
- **togglePause:** Allows the owner to pause or resume the faucet.
- **blacklistAddress:** Allows the owner to blacklist a user's address, preventing them from claiming tokens.
- **unblacklistAddress:** Allows the owner to remove a user's address from the blacklist.
- **withdrawAllFunds:** Allows the owner to withdraw all ETH and ERC-20 tokens from the faucet.
- **modifyReferralBonusPercentage:** Allows the owner to modify the percentage of referral bonus.
- **getTotalTokensClaimed:** Retrieves the total number of tokens claimed by a specific user.
- **getTotalClaimsMade:** Retrieves the total number of claims made by a specific user.
- **getTotalReferralClaims:** Retrieves the total number of referral claims made by a specific user.
- **getFaucetBalance:** Allows anyone to check the current balance of the ERC20 token held by the faucet.

## Owner Functions

The owner has control over various aspects of the faucet:
- Adjusting claim parameters (amount and frequency).
- Depositing tokens into the faucet.
- Modifying referral bonus percentage.
- Blacklisting and unblacklisting user addresses.
- Withdrawing all funds from the faucet.
- Pausing and resuming the faucet.

## Security Considerations

- Deploy with caution and thoroughly review and test parameters before deployment.
- Consider security audits and best practices to safeguard the contract and user funds.
- Use at your own risk!

## License

This ERC20 Faucet is licensed under the MIT License.

```plaintext
// SPDX-License-Identifier: MIT
