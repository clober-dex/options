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
export const WAD = new BigNumber(10).pow(18)
export const EXPIRES_AT = 1679575187 + 24 * 60 * 60
