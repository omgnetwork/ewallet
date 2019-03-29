import { BigNumber } from 'bignumber.js'
import bigInt from 'big-integer'
import _ from 'lodash'
import numeral from 'numeral'
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
  const ensureStringNumber = String(number)
  if (!ensureStringNumber) return ''
  const [integer, decimal = ''] = ensureStringNumber.split('.')
  const maybeDecimal =
    new RegExp(/\./).test(ensureStringNumber) ||
    (new RegExp(/^0*$/).test(ensureStringNumber) && ensureStringNumber.length > 1)
  const formattedInteger = numeral(integer).format()
  const formattedDecimal = decimal.replace(/[^0-9]+/g, '')
  return maybeDecimal ? `${formattedInteger}.${formattedDecimal}` : formattedInteger
}

export const formatAmount = (amount, subUnitToUnit) => {
  if (amount === null || amount === undefined || amount === '') return null
  try {
    const ensureNumberAmount = numeral(amount).value()
    const decimal = precision(ensureNumberAmount)
    const shiftedAmount = new BigNumber(ensureNumberAmount)
      .multipliedBy(Math.pow(10, decimal))
      .toNumber()
    const shiftedSubUnit = new BigNumber(subUnitToUnit).dividedBy(Math.pow(10, decimal)).toNumber()
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
      return null
    }
  } catch (error) {
    throw new Error('error formatting amount.')
  }
}
export const formatReceiveAmountToTotal = (amount, subUnitToUnit) => {
  if (amount === null || amount === undefined || amount === '') return null
  return new BigNumber(amount || 0).dividedBy(new BigNumber(subUnitToUnit)).toFormat()
}
