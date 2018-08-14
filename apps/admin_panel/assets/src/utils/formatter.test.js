import { formatAmount, formatReceiveAmountToTotal, formatNumber } from './formatter'
describe('formatter', () => {
  test('[formatNumber] should work with .', () => {
    expect(formatNumber('12312313.')).toEqual('12,312,313.')
  })
  test('[formatNumber] should format number with , correctly', () => {
    expect(formatNumber('12312313.123')).toEqual('12,312,313.123')
  })
  test('[formatNumber] should format number with , with zero', () => {
    expect(formatNumber('000000.123')).toEqual('0.123')
  })

  test('[formatNumber] should format with empty string', () => {
    expect(formatNumber('')).toEqual('')
  })
  test('[formatNumber] should remove non number', () => {
    expect(formatNumber('abc01.001')).toEqual('1.001')
  })
  test('[formatNumber] should remove zero when is not decimal', () => {
    expect(formatNumber('000050')).toEqual('50')
  })
  test('[formatNumber] should remove zero when is decimal', () => {
    expect(formatNumber('0000abc01.001')).toEqual('1.001')
  })
  test('[formatNumber] should work with number', () => {
    expect(formatNumber(0)).toEqual('0')
    expect(formatNumber(0.01)).toEqual('0.01')
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
