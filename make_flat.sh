#!/usr/bin/env bash

#pip3 install solidity-flattener --no-cache-dir -U

solidity_flattener contracts/PremiumCalculator.sol --out build/flat/PremiumCalculator_flat.sol 
solidity_flattener contracts/Product.sol --out build/flat/Product_flat.sol 

solidity_flattener test/mocs/MocBytesHelper.sol --out build/flat/MocBytesHelper_flat.sol --solc-paths="..=contracts"

#solidity_flattener contracts/insuranceProducts/Wallet.sol --out flat/insuranceProducts/Wallet_flat.sol --solc-paths="..=contracts"