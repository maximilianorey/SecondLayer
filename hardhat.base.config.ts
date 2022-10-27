import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import "hardhat-deploy";
import "hardhat-gas-reporter";
import "solidity-coverage";

// This is done to have the new matchers from waffle,
// because despite the note in https://hardhat.org/guides/waffle-testing.html?#adapting-the-tests
// the changeEtherBalance is not added because its a newer version
import dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";

dotenv.config({ path: "./.env" });

// Ensure that we have all the environment variables we need.
let mnemonic: string;
if (!process.env.mnemonic) {
  throw new Error("Please set your mnemonic in a .env file");
} else {
  mnemonic = process.env.mnemonic;
}

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
        count: 40,
      },
      chainId: 31337,
      blockGasLimit: 30000000, // 30M polygon block gas limit
    },
  },
  defaultNetwork: "hardhat",
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.7",
    settings: {
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
    alwaysGenerateOverloads: false,
  },
};

export default config;
