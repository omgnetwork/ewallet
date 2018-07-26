import { formatAmount } from './formatter'
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
})
