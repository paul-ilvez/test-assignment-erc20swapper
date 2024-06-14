# Uniswap ERC20 Swapper Contract

## Project Description
This project is a Solidity smart contract for swapping Ether to ERC-20 tokens using the Uniswap V2 decentralized exchange. The contract leverages Chainlink price feeds to optionally validate the exchange rate to ensure fair and correct swaps. This is a hiring test assignment for Eiger company.

## Features
* Swap Ether to ERC-20 Tokens: Swap Ether to any specified ERC-20 token using Uniswap V2.
* Price Feed Validation: Optionally validate the exchange rate using Chainlink price feeds to ensure fair transactions.
* Ownership Management: The contract uses OpenZeppelin's Ownable2Step for secure ownership transfer and management.
* DEX Router Update: The owner can update the Uniswap router address.
* Price Feed Toggle: The owner can enable or disable the use of the price feed for validation.

## Dependencies
* OpenZeppelin
* Uniswap V2
* Chainlink