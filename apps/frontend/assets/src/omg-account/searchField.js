export function createSearchMasterAccountQuery (value = '') {
  const matchValue = value && value.trim()
  if (!matchValue) {
    return {
      matchAny: []
    }
  }

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
      }
    ]
  }
}
