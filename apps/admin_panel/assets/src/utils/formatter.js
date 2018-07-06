import { BigNumber } from 'bignumber.js'
import bigInt from 'big-integer'

function precision (a) {
  if (!isFinite(a)) return 0
  let e = 1
  let p = 0
  while (Math.round(a * e) / e !== a) {
    e *= 10
    p++
  }
  return p
}

export const formatNumber = number => {
  return new BigNumber(number).toFormat()
}

export const formatAmount = (amount, subUnitToUnit) => {
  const ensureNumberAmount = Number(amount)
  const decimal = precision(ensureNumberAmount)
  const shiftedAmount = ensureNumberAmount * Math.pow(10, decimal)
  const shiftedSubUnit = subUnitToUnit / Math.pow(10, decimal)
  if (_.isInteger(shiftedSubUnit)) {
    if (decimal > 0) {
      return bigInt(shiftedAmount)
        .times(shiftedSubUnit)
        .toString()
    } else {
      return bigInt(ensureNumberAmount)
        .times(subUnitToUnit)
        .toString()
    }
  } else {
    return 0
  }
}

export const formatReceiveAmountToTotal = (amount, subUnitToUnit) => {
  return new BigNumber(amount || 0).dividedBy(new BigNumber(subUnitToUnit)).toFormat()
}
