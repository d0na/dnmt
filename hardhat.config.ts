import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      chainId: 31337,
    },
    localhost1: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
    localhost2: {
      url: "http://127.0.0.1:8546",
      chainId: 31338,
    }
  }
};

export default config;

