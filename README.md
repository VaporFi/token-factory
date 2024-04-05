# TokenFactory Contracts

This project allows you to deploy tokens in a secure way. With a single transaction you can:

1. Deploy an ERC20 token.
2. Create the Liquidity Pool on VaporDEX.
3. Lock the LP tokens.
4. Renounce the ownership of the memecoin contract.

## Requirements

- Node.js 18.x
- pnpm 8.x

## How to use it

Install the dependencies

`pnpm install`

Compile the contracts

`npx hardhat compile`

Deploy the contracts

`npx hardhat deploy --network localhost`
