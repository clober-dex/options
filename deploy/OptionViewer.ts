import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import {
  ARB_TOKEN_ADDRESS,
  ARBITRUM_PUTOPTION_ADDRESS,
  QUOTE_TOKEN_ADDRESS,
} from './constants'

const deployFunction: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment,
) {
  const { deployments, getNamedAccounts, network } = hre
  const { deploy } = deployments

  const { deployer } = await getNamedAccounts()

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
  })
}

deployFunction.tags = ['OptionViewer']
deployFunction.dependencies = []
export default deployFunction
