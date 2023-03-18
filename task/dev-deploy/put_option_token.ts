import { deployerTask } from '../template'

deployerTask(
  'dev:deploy-put-option-token',
  'Deploy Put Option Token',
  async (
    taskArgs: any,
    hre: any,
    deployer: { deploy: (arg0: string) => any },
  ) => {
    const optionToken = await deployer.deploy('Arbitrum$2PutOption')

    console.log(`Arbitrum$2PutOption Token deployed at ${optionToken.address}`)
  },
)
