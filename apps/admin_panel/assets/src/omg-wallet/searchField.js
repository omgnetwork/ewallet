export function createSearchAddressQuery (value = '') {
  const matchValue = value.trim()
  return {
    matchAny: [
      {
        field: 'address',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'account.name',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'name',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}
