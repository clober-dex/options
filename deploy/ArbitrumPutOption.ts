import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import BigNumber from 'bignumber.js'

import {
  ARB_TOKEN_ADDRESS,
  ARBITRUM_PUTOPTION_ADDRESS,
  EXPIRES_AT,
  QUOTE_TOKEN_ADDRESS,
} from './constants'

const deployFunction: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment,
) {
  const { deployments, getNamedAccounts, network } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()
  console.log(EXPIRES_AT(network.tags))

  for (let strikePrice = 0.5; strikePrice <= 16; strikePrice *= 2) {
    const gasFee = await hre.ethers.provider.getFeeData()
    await deploy(
      `Arbitrum$${strikePrice === 0.5 ? '0_5' : strikePrice}PutOption`,
      {
        from: deployer,
        args: [
          ARB_TOKEN_ADDRESS(network.tags),
          QUOTE_TOKEN_ADDRESS(network.tags),
          EXPIRES_AT(network.tags),
        ],
        log: true,
        maxFeePerGas: new BigNumber(
          gasFee.maxFeePerGas ? gasFee.maxFeePerGas.toString() : '1',
        )
          .multipliedBy(1.2)
          .toString(),
      },
    )
  }

  const gasFee = await hre.ethers.provider.getFeeData()
  await deploy('OptionViewer', {
    from: deployer,
    args: [
      ARB_TOKEN_ADDRESS(network.tags),
      QUOTE_TOKEN_ADDRESS(network.tags),
      ARBITRUM_PUTOPTION_ADDRESS(network.tags, 0.5),
      ARBITRUM_PUTOPTION_ADDRESS(network.tags, 1),
      ARBITRUM_PUTOPTION_ADDRESS(network.tags, 2),
      ARBITRUM_PUTOPTION_ADDRESS(network.tags, 4),
      ARBITRUM_PUTOPTION_ADDRESS(network.tags, 8),
      ARBITRUM_PUTOPTION_ADDRESS(network.tags, 16),
    ],
    log: true,
    maxFeePerGas: new BigNumber(
      gasFee.maxFeePerGas ? gasFee.maxFeePerGas.toString() : '1',
    )
      .multipliedBy(1.2)
      .toString(),
  })
}

deployFunction.tags = ['ArbitrumPutOptions']
deployFunction.dependencies = []
export default deployFunction
