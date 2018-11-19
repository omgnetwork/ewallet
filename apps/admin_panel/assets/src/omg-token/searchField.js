export function createSearchTokenQuery (value = '') {
  const matchValue = value.trim()
  return {
    matchAny: [
      {
        field: 'id',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'name',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'symbol',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}
