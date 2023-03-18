export const ARB_TOKEN_ADDRESS = (tags: Record<string, boolean>): string => {
  return 'mainnet' in tags
    ? '0x912ce59144191c1204e64559fe8253a0e49e6548'
    : '0xd2a46071A279245b25859609C3de9305e6D5b3F2'
}

export const QUOTE_TOKEN_ADDRESS = (tags: Record<string, boolean>): string => {
  return 'mainnet' in tags
    ? '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8'
    : '0xf3F8E2d3ab08BD619A794A85626970731c4174aA'
}

export const ARBITRUM_PUTOPTION_ADDRESS = (
  tags: Record<string, boolean>,
  strikePrice: number,
): string => {
  if ('mainnet' in tags) {
    switch (strikePrice) {
      case 0.5:
        return require('../deployments/42161/Arbitrum$0_5PutOption.json')
          .address
      case 1:
        return require('../deployments/42161/Arbitrum$1PutOption.json').address
      case 2:
        return require('../deployments/42161/Arbitrum$2PutOption.json').address
      case 4:
        return require('../deployments/42161/Arbitrum$4PutOption.json').address
      case 8:
        return require('../deployments/42161/Arbitrum$8PutOption.json').address
      case 16:
        return require('../deployments/42161/Arbitrum$16PutOption.json').address
    }
  }
  if ('testnet' in tags) {
    switch (strikePrice) {
      case 0.5:
        return require('../deployments/421613/Arbitrum$0_5PutOption.json')
          .address
      case 1:
        return require('../deployments/421613/Arbitrum$1PutOption.json').address
      case 2:
        return require('../deployments/421613/Arbitrum$2PutOption.json').address
      case 4:
        return require('../deployments/421613/Arbitrum$4PutOption.json').address
      case 8:
        return require('../deployments/421613/Arbitrum$8PutOption.json').address
      case 16:
        return require('../deployments/421613/Arbitrum$16PutOption.json')
          .address
    }
  }
  throw new Error('ArbitrumPutOption is not deployed on this network')
}
