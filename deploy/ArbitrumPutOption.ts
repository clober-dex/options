import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import { ARB_TOKEN_ADDRESS, QUOTE_TOKEN_ADDRESS } from './constants'

const deployFunction: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment,
) {
  const { deployments, getNamedAccounts, network } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

  for (let strikePrice = 0.5; strikePrice <= 16; strikePrice *= 2) {
    await deploy(
      `Arbitrum$${strikePrice === 0.5 ? '0_5' : strikePrice}PutOption`,
      {
        from: deployer,
        args: [
          ARB_TOKEN_ADDRESS(network.tags),
          QUOTE_TOKEN_ADDRESS(network.tags),
        ],
        log: true,
      },
    )
  }
}

deployFunction.tags = ['ArbitrumPutOptions']
deployFunction.dependencies = []
export default deployFunction
