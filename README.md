# Kitty Connect

<p align="center">
<img src="https://res.cloudinary.com/droqoz7lg/image/upload/q_90/dpr_2.0/c_fill,g_auto,h_320,w_320/f_auto/v1/company/lisdxtcddudcvde6sucn?_a=BATAUVAA0" width="500" alt="Kitty Connect">
</p>

# Contest Details

### Prize Pool

- High - 100xp
- Medium - 20xp
- Low - 2xp

- Starts: March 28, 2024 Noon UTC
- Ends: April 04, 2024 Noon UTC

### Stats

- nSLOC: 235
- Complexity Score: 193

# About the Project

This project allows users to buy a cute cat from our branches and mint NFT for buying a cat. The NFT will be used to track the cat info and all related data for a particular cat corresponding to their token ids.
Kitty Owner can also Bridge their NFT from one chain to another chain via [`Chainlink CCIP`](https://docs.chain.link/ccip).

The codebase is broken up into 2 contracts (In Scope):

- `KittyConnect.sol`
- `KittyBridge.sol`

## KittyConnect

This contract allows users to buy a cute cat from our branches and mint NFT for buying a cat. The NFT will be used to track the cat info and all related data for a particular cat corresponding to their token ids.

## KittyBridge

This contract allows users to bridge their Kitty NFT from one chain to another chain via [`Chainlink CCIP`](https://docs.chain.link/ccip).

## Roles in the Project:

1. Cat Owner
   - User who buy the cat from our branches and mint NFT for buying a cat.
2. Shop Partner
   - Shop partner provide services to the cat owner to buy cat.
3. KittyConnect Owner
   - Owner of the contract who can transfer the ownership of the contract to another address.

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```bash
git clone https://github.com/Cyfrin/2024-03-kitty-connect
cd 2024-03-kitty-connect
```

### Install Dependencies

```bash
make
```

or

```bash
forge build
```

## Testing

```bash
forge test
```

### Test Coverage

```bash
forge coverage
```

### Compiling

```bash
forge compile
```

# How this Project Works

## Buying a Cat

A user is required to visit our shop partner to buy a cat. The shop partner will call the function from KittyConnect contract to mint NFT for buying a cat. (This NFT will track all the data related to the cat)

## Bridge Kitty NFT from one chain to another chain

User can bridge Kitty NFT from one chain to another chain by calling this function from KittyConnect contract. This involves burning of the kitty NFT on the source chain and minting on the destination chain. Bridging is powered by chainlink CCIP.

## Transferring Ownership of cat to new owner

Sometimes a user wants to transfer their cat to a new owner, this can be easily done by transferring the Kitty NFT to that desired owner.
A user is first required to approve the kitty NFT to the new owner, and is then required to visit our shop partner to finally facilitate transfer the ownership of the cat to the new owner.

# Known Issues

- there is one known bug while bridging the NFT to other chain, the previousOwners of the cat are not passed because they may cost a large amount of gas.
