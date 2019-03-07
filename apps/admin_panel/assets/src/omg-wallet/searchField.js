export function createSearchAddressQuery (value = '') {
  if (!value) return
  const matchValue = value.trim()

  if (matchValue === '') {
    return { matchAny: [] }
  }

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
