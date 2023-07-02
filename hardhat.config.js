module.exports = {
  networks: {
    hardhat: {
      // For local development and testing
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545", // Testnet URL
      accounts: [
        "79c82bad72ba6320e101df76e85368d68f0a94f5d1db35831d0470b9135964aa",
      ], // Array of private keys for accounts to be used for testing
    },
  },
  solidity: {
    version: "0.8.0", // Compiler version
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
