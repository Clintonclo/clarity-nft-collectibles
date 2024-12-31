# Clarinet 2.0 NFT Collectible Smart Contract

This repository contains a **Clarinet 2.0** smart contract for managing **non-fungible tokens (NFTs)**. The contract allows for the creation, burning, transferring, and batch processing of collectibles, with strict ownership and URI validation. It provides an admin role for controlling critical operations, such as minting and modifying tokens.

## Features

- **Admin Role**: The platform admin (tx-sender) is authorized to mint new tokens and batch-create tokens.
- **Collectible Management**:
  - Minting new collectibles.
  - Batch minting up to 50 collectibles at a time.
  - Modifying the URI of a collectible.
  - Burning collectibles with ownership checks.
  - Transferring ownership of collectibles.
- **Validation**: 
  - URI validity checks.
  - Ownership verification for transfers and burning.
  - Check if a collectible is already burned.

## Contract Functions

### Public Functions
- `create-collectible(uri: string)`: Creates a new collectible, requires admin privileges.
- `batch-create(uris: list)`: Creates a batch of up to 50 collectibles at once, requires admin privileges.
- `burn-collectible(token-id: uint)`: Burns a collectible after checking if the sender is the owner.
- `transfer-collectible(token-id: uint, from: principal, to: principal)`: Transfers a collectible from one owner to another.
- `modify-collectible-uri(token-id: uint, updated-uri: string)`: Allows the owner to modify the URI associated with a collectible.

### Read-Only Functions
- `get-collectible-uri(token-id: uint)`: Retrieves the URI associated with a specific collectible.
- `fetch-owner(token-id: uint)`: Retrieves the current owner of a collectible.
- `get-current-collectible-id()`: Retrieves the current collectible ID.
- `has-been-burned(token-id: uint)`: Checks if a collectible has been burned.
- `list-batch-collectibles(start-id: uint, count: uint)`: Retrieves a batch of collectibles starting from a given ID.

## Constants
The contract defines several constants for error codes, batch size limits, and platform admin identification:
- `platform-admin`: The platform admin address.
- `max-collectible-batch`: Maximum number of collectibles allowed in a batch (50).
- Error codes for various failure scenarios (e.g., `error-admin-only`, `error-not-collectible-owner`).

## Data Structures
- `collectible-token`: The non-fungible token used for collectibles.
- `current-collectible-id`: Keeps track of the latest collectible ID.
- `collectible-uri`: Maps a collectible ID to its associated URI.
- `burned-collectibles`: Maps a collectible ID to a boolean indicating whether it has been burned.
- `batch-info`: Stores batch-related information for minting operations.

## Private Functions
- `verify-collectible-owner`: Verifies the ownership of a collectible.
- `check-uri-validity`: Validates the format of a URI.
- `is-collectible-burned`: Checks if a collectible has been burned.
- `mint-collectible`: Mints a new collectible with the provided URI.

## Initialization
The contract initializes with the `current-collectible-id` set to 0.

## Installation

To interact with this smart contract, you need the **Clarinet** framework installed. Follow the instructions from the [Clarinet documentation](https://docs.clarinet.xyz/) to set up your environment.

```bash
# Install Clarinet
curl https://github.com/hiRoFaT/clarinet/releases/download/v0.9.0/clarinet-v0.9.0-linux-x86_64.tar.gz | tar -xvzf -
```

## Usage

Once Clarinet is set up, you can deploy this smart contract to your local or testnet environment. Here's how to deploy and interact with the contract:

```bash
# Deploy the contract
clarinet deploy

# Call functions like minting a collectible
clarinet call create-collectible '{"uri": "https://example.com/collectible/1"}'

# Transfer a collectible
clarinet call transfer-collectible '{"token-id": 1, "from": "principal-address", "to": "new-principal-address"}'
```

## Errors
The contract includes various error codes to help handle failure cases:
- `error-admin-only`: Only the admin can perform this action.
- `error-not-collectible-owner`: The sender is not the owner of the collectible.
- `error-collectible-not-found`: The collectible could not be found.
- `error-invalid-uri`: The provided URI is not valid.
- `error-burn-failed`: The burning operation failed.
- `error-already-burned`: The collectible has already been burned.
- `error-uri-update-not-allowed`: The owner is not allowed to update the URI.

## License

This contract is licensed under the [MIT License](LICENSE).
