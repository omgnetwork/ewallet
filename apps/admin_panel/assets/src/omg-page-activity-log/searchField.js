export function createSearchActivityLogQuery (value = '') {
  const matchValue = value.trim()
  if (!value) return {}
  return {
    matchAny: [
      {
        field: 'originator.id',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}
