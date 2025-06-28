# Stacks DAO Governance Contract

A decentralized autonomous organization (DAO) governance contract built on the Stacks blockchain that enables community-driven decision making through stake-weighted voting.

## Overview

This smart contract implements a full-featured DAO governance system where members can create proposals, vote on them using their stake as voting power, and execute approved proposals. The system includes time-based proposal expiration, quorum requirements, and support for executable on-chain actions.

## Features

- **Stake-Weighted Voting**: Vote power is proportional to the member's stake in the DAO
- **Proposal Management**: Create, vote on, and execute governance proposals
- **Time-Based Expiration**: Proposals automatically expire after a defined block period
- **Quorum Requirements**: Minimum participation threshold for proposal validity
- **Member Management**: Add/remove members with stake tracking
- **Executable Proposals**: Support for proposals that can trigger contract calls
- **Comprehensive Validation**: Protection against double voting and unauthorized access

## Contract Structure

### Constants

- `PROPOSAL-DURATION`: 144 blocks (~1 day with 10-minute block times)
- `MINIMUM-STAKE`: 100 STX minimum stake requirement for membership
- `QUORUM-PERCENTAGE`: 30% of total stake must participate for valid proposals

### Data Structures

- **Members Map**: Maps principal addresses to their stake amounts
- **Proposals Map**: Stores all proposal metadata and voting results
- **Votes Map**: Tracks individual votes to prevent double voting

## Usage

### Setting Up the DAO

1. Deploy the contract (deployer becomes initial DAO owner)
2. Add members with their stakes:
```clarity
(contract-call? .stacks-govern-contract add-member 'SP1234... u100000000) ;; 100 STX
```

### Creating Proposals

Members can create proposals with optional executable actions:
```clarity
(contract-call? .stacks-govern-contract create-proposal 
  "Increase minimum stake" 
  "Proposal to increase the minimum stake to 200 STX" 
  (some "https://dao.example.com/proposal/1")
  none 
  none 
  none)
```

### Voting on Proposals

Members vote using their stake as voting power:
```clarity
(contract-call? .stacks-govern-contract vote u1 true) ;; Vote yes on proposal 1
```

### Executing Proposals

Once approved and quorum is met, any member can execute the proposal:
```clarity
(contract-call? .stacks-govern-contract execute-proposal u1)
```

## Function Reference

### Public Functions

#### Administrative Functions
- `set-dao-owner(new-owner: principal)` - Transfer DAO ownership
- `add-member(user: principal, stake: uint)` - Add new DAO member
- `remove-member(user: principal)` - Remove member from DAO

#### Governance Functions
- `create-proposal(...)` - Create a new governance proposal
- `vote(proposal-id: uint, vote-value: bool)` - Vote on a proposal
- `execute-proposal(proposal-id: uint)` - Execute an approved proposal

### Read-Only Functions
- `get-proposal(proposal-id: uint)` - Get proposal details
- `get-member-stake(member: principal)` - Get member's stake amount
- `get-total-stake()` - Get total DAO stake
- `get-proposal-count()` - Get total number of proposals
- `get-proposal-status(proposal-id: uint)` - Get current proposal status

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR-NOT-AUTHORIZED | Caller lacks required permissions |
| u101 | ERR-PROPOSAL-EXISTS | Proposal already exists |
| u102 | ERR-PROPOSAL-EXPIRED | Proposal has expired |
| u103 | ERR-PROPOSAL-ACTIVE | Proposal is still active |
| u104 | ERR-PROPOSAL-NOT-FOUND | Proposal does not exist |
| u105 | ERR-ALREADY-VOTED | User has already voted on this proposal |
| u106 | ERR-NOT-MEMBER | User is not a DAO member |
| u107 | ERR-INSUFFICIENT-STAKE | Stake amount below minimum requirement |
| u108 | ERR-QUORUM-NOT-REACHED | Insufficient votes for quorum |
| u109 | ERR-PROPOSAL-NOT-APPROVED | Proposal was not approved |

## Development

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- Node.js (for testing framework)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd stacks-govern-app
```

2. Check contract syntax:
```bash
clarinet check
```

3. Run tests:
```bash
clarinet test
```

### Project Structure

```
├── Clarinet.toml           # Clarinet configuration
├── contracts/
│   └── stacks-govern-contract.clar  # Main DAO contract
├── tests/
│   └── stacks-govern-contract_test.ts  # Contract tests
├── settings/
│   ├── Devnet.toml        # Development network settings
│   ├── Testnet.toml       # Testnet settings
│   └── Mainnet.toml       # Mainnet settings
└── README.md              # This file
```

## Security Considerations

- **Authorization Checks**: All administrative functions require proper authorization
- **Double Voting Prevention**: Users cannot vote multiple times on the same proposal
- **Stake Validation**: Proper validation of stake amounts and membership status
- **Time-Based Controls**: Proposals have expiration times to prevent stale governance
- **Quorum Requirements**: Minimum participation ensures legitimate governance decisions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

If you have questions or need help with the DAO governance contract, please:

1. Check the existing issues in the repository
2. Review the contract documentation
3. Open a new issue with detailed information about your question or problem

---

Built with ❤️ for the Stacks ecosystem
