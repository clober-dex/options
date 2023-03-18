import BigNumber from 'bignumber.js'

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
    throw new Error('ArbitrumPutOption is not deployed on mainnet')
  }
  if ('testnet' in tags) {
    switch (strikePrice) {
      case 0.5:
        return '0x5D45a5ADa82ecf78021E9b4518036a3B649e5a35'
      case 1:
        return '0x0820Ed58A1f0d6FF42712a1877E368f183C94219'
      case 2:
        return '0xefa4841C3FA0bCC33987DA112f7EA3b1aC7541D9'
      case 4:
        return '0x8705373587dA69FB99181938E1463982f0Fa5b56'
      case 8:
        return '0xb28f8E47818dd44FA3d94928BE42809494FD506B'
      case 16:
        return '0x5c4871CA3EB28C1c552E5DaCF31B20BE939E156d'
    }
  }
  throw new Error('ArbitrumPutOption is not deployed on this network')
}
export const WAD = new BigNumber(10).pow(18)
export const EXPIRES_AT = 1679575187 + 24 * 60 * 60
