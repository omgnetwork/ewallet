import { BigNumber } from 'bignumber.js'

export const weiToGwei = wei => new BigNumber(wei).dividedBy(1000000000)
export const gweiToWei = gwei => new BigNumber(gwei).multipliedBy(1000000000)
