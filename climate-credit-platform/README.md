# Carbon Credit Trading Platform

## Overview

The Carbon Credit Trading Platform is a smart contract built on the Stacks blockchain that enables the tokenization, validation, and trading of carbon credits. This marketplace provides a transparent and efficient way to buy, sell, and transfer carbon credits with robust metadata tracking and verification.

## Features

- **Tokenized Carbon Credits**: Convert real-world carbon offsets into tradable digital assets
- **Detailed Metadata**: Track critical information including issuer, production year, verification protocol, and project type
- **Transparent Marketplace**: List, buy, and sell carbon credits with clear pricing and ownership
- **Direct Transfers**: Transfer carbon credits directly between users
- **Issue Reporting**: Submit reports for problematic carbon credits
- **Administrative Controls**: Secure issuance of new carbon credits by authorized administrators

## Contract Structure

The smart contract uses the following data structures:

1. **User Credit Holdings**: Tracks carbon credit balances for each user
2. **Carbon Credit Details**: Stores metadata for each type of carbon credit
3. **Market Listings**: Contains active marketplace listings of carbon credits for sale

## Functions

### Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-user-balance` | Retrieves a user's carbon credit balance |
| `get-credit-metadata` | Gets detailed information about a specific carbon credit type |
| `get-market-listing` | Retrieves details about a specific marketplace listing |

### Public Functions

| Function | Description |
|----------|-------------|
| `create-market-listing` | Creates a new listing to sell carbon credits |
| `remove-market-listing` | Removes a listing from the marketplace |
| `buy-carbon-credits` | Executes a purchase of carbon credits from a listing |
| `transfer-carbon-credits` | Transfers carbon credits directly between users |
| `modify-market-listing` | Updates the quantity and price of an existing listing |
| `submit-credit-issue-report` | Reports issues with specific carbon credits |
| `issue-new-carbon-credits` | Creates new carbon credits (admin only) |

## Usage Examples

### Creating a Market Listing

```clarity
;; List 10 carbon credits (ID: 1) for sale at 500 STX each
(contract-call? .carbon-credit-platform create-market-listing u1 u10 u500)
```

### Buying Carbon Credits

```clarity
;; Purchase carbon credits from listing ID 3
(contract-call? .carbon-credit-platform buy-carbon-credits u3)
```

### Transferring Carbon Credits

```clarity
;; Transfer 5 carbon credits to another user
(contract-call? .carbon-credit-platform transfer-carbon-credits 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u5)
```

### Issuing New Carbon Credits (Admin Only)

```clarity
;; Issue 1000 new carbon credits for the year 2024 with Gold Standard verification
(contract-call? .carbon-credit-platform issue-new-carbon-credits u1000 u2024 "Gold Standard" "Reforestation")
```

## Error Codes

| Code | Description |
|------|-------------|
| `ERR-ADMIN-ONLY` (u100) | Action restricted to admin |
| `ERR-BALANCE-TOO-LOW` (u101) | User lacks sufficient credits |
| `ERR-ZERO-OR-NEGATIVE-PRICE` (u102) | Invalid pricing input |
| `ERR-LISTING-DOES-NOT-EXIST` (u103) | Listing not found |
| `ERR-PERMISSION-DENIED` (u104) | Unauthorized action |
| `ERR-INVALID-CREDIT-DATA` (u105) | Invalid credit metadata |
| `ERR-YEAR-OUT-OF-RANGE` (u106) | Invalid year input |
| `ERR-UNKNOWN-VERIFICATION-STANDARD` (u107) | Unknown verification standard |
| `ERR-UNRECOGNIZED-PROJECT-TYPE` (u108) | Invalid project type |
| `ERR-LISTING-ALREADY-EXISTS` (u109) | Duplicate listing |
| `ERR-LISTING-INACTIVE` (u110) | Listing not available |

## Security Considerations

- Only the contract administrator can issue new carbon credits
- Users can only modify or remove their own listings
- Balance checks ensure users cannot transfer or sell more credits than they own
- Price validations prevent zero or negative pricing

## Integration

To integrate with the Carbon Credit Trading Platform, deploy the contract on the Stacks blockchain and interact with it using Clarity contract calls. The contract can be extended to include additional features such as:

- Enhanced verification processes
- Support for different types of environmental credits
- Integration with real-world carbon offset projects
- Automated reporting and compliance mechanisms