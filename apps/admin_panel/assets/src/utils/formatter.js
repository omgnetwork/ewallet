export const formatNumber = number => {
  return Number(number).toLocaleString(undefined, { maximumSignificantDigits: 18 })
}
