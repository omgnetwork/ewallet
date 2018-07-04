import { BigNumber } from 'bignumber.js'
export const formatNumber = number => {
  return new BigNumber(number).format()
}

export const formatSendAmountToTotal = (amount, subUnitToUnit) => {
  return new BigNumber(amount || 0).multipliedBy(new BigNumber(subUnitToUnit)).toNumber()
}

export const formatRecieveAmountToTotal = (amount, subUnitToUnit) => {
  return new BigNumber(amount || 0).dividedBy(new BigNumber(subUnitToUnit)).toFormat()
}
export const formatRecieveAmountToTotalNumber = (amount, subUnitToUnit) => {
  return new BigNumber(amount || 0).dividedBy(new BigNumber(subUnitToUnit)).toNumber()
}
