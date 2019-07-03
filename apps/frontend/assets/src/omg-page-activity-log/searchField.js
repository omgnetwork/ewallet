export function createSearchActivityLogQuery (value = '') {
  const matchValue = value && value.trim()
  if (!matchValue) {
    return {
      matchAny: []
    }
  }

  return {
    matchAny: [
      {
        field: 'originator_identifier',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'target_identifier',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'action',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'originator_type',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'target_type',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}
