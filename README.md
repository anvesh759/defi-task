# CommunityCredentials

A simple on-chain credential system written in Solidity for a community or informal group. The contract lets an admin issue non-transferable credentials to wallet addresses, store multiple credentials per address, calculate a trust score from those credentials, and gate access based on that score.

## Overview

This project is designed to solve a common problem in communities, clubs, learning groups, and volunteer networks: people contribute over time, but those contributions are often not recorded in a formal way. This contract stores those contributions on-chain as credentials tied to wallet addresses.

Each credential contains:

- a `title`
- a `level`
- an `issuedAt` timestamp

The contract supports:

- admin-only credential issuance
- storage of multiple credentials per address
- public lookup of any wallet’s credential list
- trust score calculation
- an `accessGranted()` gate based on the caller’s trust score
- duplicate-title prevention for the same wallet
- non-transferable credential records

---

## Contract Summary

### Contract Name
`CommunityCredentials`

### Solidity Version
`^0.8.20`

### Core Idea
The deployer becomes the admin. The admin can issue credentials to member wallets. Every credential is stored permanently under the recipient wallet, and there is no transfer function, so the credential cannot be moved to another address.

---

## Features

### 1. Admin-Controlled Credential Issuance
Only the deployer can issue credentials.

The contract uses:

- `admin` as the deployer address
- `onlyAdmin` modifier to restrict issuance

This keeps the system controlled and prevents self-issued claims.

### 2. Credential Storage Per Address
Credentials are stored in:

- `mapping(address => Credential[]) private credentialsByMember`

This allows one wallet to hold multiple credentials over time.

### 3. Public Credential Lookup
Anyone can read a wallet’s full credential list using:

- `getCredentials(address member)`

There is also a helper function:

- `credentialCount(address member)`

### 4. Trust Score Calculation
The contract calculates a trust score from stored credentials.

Current formula:

- each credential gives `5` base points
- plus `level^2 * 5`

So the values are:

- level 1 → `10`
- level 2 → `25`
- level 3 → `50`

This formula rewards both:
- the number of credentials
- the level of each credential

### 5. Access Gate
The function:

- `accessGranted()`

returns `true` only if the caller’s trust score is at least the threshold defined by:

- `ACCESS_THRESHOLD`

If the score is too low, the function reverts with:

- `"Trust score below access threshold"`

### 6. Non-Transferable Credentials
There is no transfer, approval, or reassignment logic in the contract.

Credentials are stored directly under the recipient’s address, which makes them bound to that wallet permanently.

### 7. Duplicate Credential Handling
The contract rejects duplicate titles for the same wallet.

If the admin tries to issue the same title twice to the same address, the transaction reverts with:

- `"Credential title already issued"`

This prevents score inflation from repeated issuance of the same achievement.

---

## Data Structure

### Credential Struct

```solidity
struct Credential {
    string title;
    uint256 level;
    uint256 issuedAt;
}
```

Each credential stores:
- `title`: the name of the achievement or contribution
- `level`: the importance level, from 1 to 3
- `issuedAt`: the block timestamp when it was issued

### Storage Mappings

```solidity
mapping(address => Credential[]) private credentialsByMember;
mapping(address => mapping(bytes32 => bool)) private hasCredentialTitle;
```

- `credentialsByMember` stores all credentials for each wallet
- `hasCredentialTitle` prevents the same title from being issued twice to the same wallet

---

## Functions

### `issueCredential(address member, string calldata title, uint256 level)`
Issues a new credential to a wallet.

Requirements:
- caller must be the admin
- member address must not be zero
- title must not be empty
- level must be between 1 and 3
- duplicate title for the same wallet is rejected

### `getCredentials(address member)`
Returns the full list of credentials stored for a wallet.

### `credentialCount(address member)`
Returns how many credentials a wallet has.

### `trustScore(address member)`
Calculates the trust score for a wallet by looping through all stored credentials and summing their values.

### `accessGranted()`
Checks whether the caller’s trust score is at or above the threshold.

Returns:
- `true` if the score is high enough

Reverts:
- if the caller does not meet the threshold

---

## Trust Score Design

The formula used in this contract is:

```solidity
score += 5 + (level * level * 5);
```

### Why this formula?
This formula was chosen because it rewards both quantity and quality:

- the base `5` points reward participation
- squaring the level makes higher-level contributions matter more
- the scoring is simple to understand and easy to test in Remix

### Example
If a wallet has:
- one level 3 credential
- one level 2 credential

Then the score is:

- level 3 → `50`
- level 2 → `25`

Total:
- `75`

---

## Non-Transferability

Credentials are non-transferable by design.

### How it is enforced
The contract does not include:
- transfer functions
- approval functions
- owner-change functions
- any way to move a credential from one wallet to another

Instead, credentials are written directly into the recipient wallet’s storage slot in:

- `credentialsByMember[member]`

### Why this matters
If credentials could be transferred, a wallet could buy or borrow someone else’s reputation. Keeping credentials tied to the original wallet preserves the integrity of the trust system.

---

## Duplicate Title Policy

The contract rejects duplicate titles for the same wallet.

### Reasoning
If the same achievement title could be issued repeatedly, a member could inflate their trust score by receiving the same credential many times. Rejecting duplicates keeps the score meaningful and makes each credential represent a distinct contribution.

### Implementation
The contract hashes the title and records whether that title has already been issued to that wallet:

```solidity
mapping(address => mapping(bytes32 => bool)) private hasCredentialTitle;
```

Before issuing a credential, the contract checks that the title has not already been used for that wallet.

---

## How to Deploy in Remix

### 1. Open Remix
Use Remix IDE in your browser.

### 2. Create a new file
Save the contract as:

- `CommunityCredentials.sol`

### 3. Compile
Select Solidity compiler version:

- `0.8.20` or compatible `0.8.x`

Click **Compile**.

### 4. Deploy
Go to the **Deploy & Run Transactions** tab.

Choose an account and click **Deploy**.

The deploying account becomes the admin automatically.

---

## How to Test in Remix

### Issue credentials
Call `issueCredential` from the admin account.

Example:
- member: another account address
- title: `Open Source Contributor`
- level: `3`

Then issue another credential with a different title.

### Check stored credentials
Call:
- `getCredentials(memberAddress)`

You should see all issued credentials for that wallet.

### Check trust score
Call:
- `trustScore(memberAddress)`

The result should match the formula used in the contract.

### Test access granted
Switch to the member account and call:
- `accessGranted()`

If the trust score meets the threshold, the call returns `true`.

### Test access denied
Use a wallet with no credentials and call:
- `accessGranted()`

The call should revert with:
- `Trust score below access threshold`

### Test duplicate rejection
Try issuing the same title twice to the same wallet.

The second call should revert with:
- `Credential title already issued`

---

## Suggested Project Structure

```text
project-root/
├── contracts/
│   └── CommunityCredentials.sol
├── screenshots/
│   ├── accessGranted_success.png
│   └── accessGranted_failure.png
└── README.md
```

---

## Notes

- This contract is intentionally simple and educational.
- It is designed for a Remix-based submission.
- It uses clear storage patterns and comments to make design decisions easy to understand.
- It does not rely on external libraries.

---

## License

MIT
