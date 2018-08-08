import { formatAmount, formatReceiveAmountToTotal, formatNumber } from './formatter'
describe('formatter', () => {
  test('format number should work with .', () => {
    expect(formatNumber('12312313.')).toEqual('12312313.')
  })
  test('[formatAmount] should format amount with the right precision when provide incorrect decimal', () => {
    const amount = 100000000
    const subunitToUnit = 10000000000
    expect(formatAmount(amount, subunitToUnit)).toEqual('1000000000000000000')
  })
  test('[formatAmount] should return null if amount demical is less than amount precision', () => {
    const amount = 1.12345
    const subunitToUnit = 100
    expect(formatAmount(amount, subunitToUnit)).toEqual(null)
  })
  test('[formatAmount] should format amount correctly with numbers string', () => {
    const amount = '1.12345'
    const subunitToUnit = 10000000
    expect(formatAmount(amount, subunitToUnit)).toEqual('11234500')
  })
  test('[formatAmount] should format amount correctly with comma', () => {
    const amount = '10,000.12345'
    const subunitToUnit = 100000000000
    expect(formatAmount(amount, subunitToUnit)).toEqual('1000012345000000')
  })
  test('[formatReceiveAmountToTotal] should return 0 amount is falsy', () => {
    const subunitToUnit = 100
    expect(formatReceiveAmountToTotal(null, subunitToUnit)).toEqual(null)
    expect(formatReceiveAmountToTotal(undefined, subunitToUnit)).toEqual(null)
    expect(formatReceiveAmountToTotal(0, subunitToUnit)).toEqual('0')
  })
})
