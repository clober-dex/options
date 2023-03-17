import fs from 'fs'

import * as dotenv from 'dotenv'
// eslint-disable-next-line import/order
import readlineSync from 'readline-sync'

import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import 'hardhat-deploy'
import '@nomiclabs/hardhat-ethers'
import 'hardhat-gas-reporter'
import 'hardhat-contract-sizer'
import 'hardhat-abi-exporter'
import 'solidity-coverage'

import './task/index.ts'

dotenv.config()

import { HardhatConfig } from 'hardhat/types'

import { CHAINID, NETWORK } from './utils/constant'

let privateKey: string

const getMainnetPrivateKey = () => {
  let network
  for (const [i, arg] of Object.entries(process.argv)) {
    if (arg === '--network') {
      network = process.argv[parseInt(i) + 1]
    }
  }

  if (network === NETWORK.MAINNET) {
    if (privateKey) {
      return privateKey
    }
    const keythereum = require('keythereum')

    const KEYSTORE = './mainnet-deploy-key-store.json'
    const PASSWORD = readlineSync.question('Password: ', {
      hideEchoBack: true,
    })
    if (PASSWORD === 'view') {
      return '0x0000000000000000000000000000000000000000000000000000000000000001'
    }

    const keyObject = JSON.parse(fs.readFileSync(KEYSTORE).toString())
    privateKey = '0x' + keythereum.recover(PASSWORD, keyObject).toString('hex')
    return privateKey
  }
  return '0x0000000000000000000000000000000000000000000000000000000000000001'
}

const config: HardhatConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          evmVersion: 'london',
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
    overrides: {},
  },
  // @ts-ignore
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v5',
  },
  defaultNetwork: 'hardhat',
  networks: {
    [NETWORK.MAINNET]: {
      url: process.env.MAINNET_NODE_URL ?? '',
      chainId: CHAINID.MAINNET,
      accounts: [getMainnetPrivateKey()],
      gas: 'auto',
      gasPrice: 1000000000, // 1Gwei
      gasMultiplier: 1,
      timeout: 3000000,
      httpHeaders: {},
      live: true,
      saveDeployments: true,
      tags: ['mainnet', 'prod'],
      companionNetworks: {},
    },
    [NETWORK.GOERLI_DEV]: {
      url: process.env.GOERLI_NODE_URL ?? '',
      chainId: CHAINID.GOERLI,
      accounts:
        process.env.GOERLI_DEV_PRIVATE_KEY !== undefined
          ? [process.env.GOERLI_DEV_PRIVATE_KEY]
          : [],
      gas: 'auto',
      gasPrice: 'auto',
      gasMultiplier: 1,
      timeout: 3000000,
      httpHeaders: {},
      live: true,
      saveDeployments: true,
      tags: ['testnet', 'dev'],
      companionNetworks: {},
    },
    [NETWORK.POLYGON_DEV]: {
      url: process.env.POLYGON_NODE_URL ?? '',
      chainId: CHAINID.POLYGON,
      accounts:
        process.env.POLYGON_DEV_PRIVATE_KEY !== undefined
          ? [process.env.POLYGON_DEV_PRIVATE_KEY]
          : [],
      gas: 'auto',
      gasPrice: 'auto',
      gasMultiplier: 1,
      timeout: 3000000,
      httpHeaders: {},
      live: true,
      saveDeployments: true,
      tags: ['mainnet', 'dev'],
      companionNetworks: {},
    },
    [NETWORK.GOERLI_BETA]: {
      url: process.env.GOERLI_NODE_URL ?? '',
      chainId: CHAINID.GOERLI,
      accounts:
        process.env.GOERLI_BETA_PRIVATE_KEY !== undefined
          ? [process.env.GOERLI_BETA_PRIVATE_KEY]
          : [],
      gas: 'auto',
      gasPrice: 'auto',
      gasMultiplier: 1,
      timeout: 3000000,
      httpHeaders: {},
      live: true,
      saveDeployments: true,
      tags: ['testnet', 'dev'],
      companionNetworks: {},
    },
    [NETWORK.POLYGON_BETA]: {
      url: process.env.POLYGON_NODE_URL ?? '',
      chainId: CHAINID.POLYGON,
      accounts:
        process.env.POLYGON_BETA_PRIVATE_KEY !== undefined
          ? [process.env.POLYGON_BETA_PRIVATE_KEY]
          : [],
      gas: 'auto',
      gasPrice: 'auto',
      gasMultiplier: 1,
      timeout: 3000000,
      httpHeaders: {},
      live: true,
      saveDeployments: true,
      tags: ['mainnet', 'dev'],
      companionNetworks: {},
    },
    [NETWORK.HARDHAT]: {
      chainId: CHAINID.HARDHAT,
      gas: 20000000,
      gasPrice: 250000000000,
      gasMultiplier: 1,
      hardfork: 'london',
      // @ts-ignore
      // forking: {
      //   enabled: true,
      //   url: 'ARCHIVE_NODE_URL',
      // },
      mining: {
        auto: true,
        interval: 0,
        mempool: {
          order: 'fifo',
        },
      },
      accounts: {
        mnemonic:
          'loop curious foster tank depart vintage regret net frozen version expire vacant there zebra world',
        initialIndex: 0,
        count: 10,
        path: "m/44'/60'/0'/0",
        accountsBalance: '10000000000000000000000000000',
        passphrase: '',
      },
      blockGasLimit: 200000000,
      // @ts-ignore
      minGasPrice: undefined,
      throwOnTransactionFailures: true,
      throwOnCallFailures: true,
      allowUnlimitedContractSize: true,
      initialDate: new Date().toISOString(),
      loggingEnabled: false,
      // @ts-ignore
      chains: undefined,
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  abiExporter: [
    // @ts-ignore
    {
      path: './abi',
      runOnCompile: false,
      clear: true,
      flat: true,
      only: [],
      except: [],
      spacing: 2,
      pretty: false,
      filter: () => true,
    },
  ],
  mocha: {
    timeout: 40000000,
    require: ['hardhat/register'],
  },
  // @ts-ignore
  contractSizer: {
    runOnCompile: true,
  },
}

export default config
