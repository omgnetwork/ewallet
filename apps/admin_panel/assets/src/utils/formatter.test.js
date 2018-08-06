import { formatAmount, formatReceiveAmountToTotal } from './formatter'
describe('formatter', () => {
  test('should format amount with the right precision', () => {
    const amount = 100000000
    const subunitToUnit = 10000000000
    expect(formatAmount(amount, subunitToUnit)).toEqual('1000000000000000000')
  })
  test('should return null if amount demical is less than amount precision', () => {
    const amount = 1.12345
    const subunitToUnit = 100
    expect(formatAmount(amount, subunitToUnit)).toEqual(null)
  })
  test('should format amount correctly with numbers string', () => {
    const amount = '1.12345'
    const subunitToUnit = 10000000
    expect(formatAmount(amount, subunitToUnit)).toEqual('11234500')
  })
  test('should format amount correctly with comma', () => {
    const amount = '10,000.12345'
    const subunitToUnit = 100000000000
    expect(formatAmount(amount, subunitToUnit)).toEqual('1000012345000000')
  })
  test('should return 0 amount is falsy', () => {
    const subunitToUnit = 100
    expect(formatReceiveAmountToTotal(null, subunitToUnit)).toEqual('0')
    expect(formatReceiveAmountToTotal(0, subunitToUnit)).toEqual('0')
    expect(formatReceiveAmountToTotal(undefined, subunitToUnit)).toEqual('0')
  })
})
