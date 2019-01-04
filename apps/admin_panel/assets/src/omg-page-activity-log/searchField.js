export function createSearchActivityLogQuery (value = '') {
  const matchValue = value.trim()
  if (!value) return {}
  return {
    matchAny: [
      {
        field: 'originator.id',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'originator.address',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'target.id',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'target.address',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'action',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}
