export function createSearchMasterAccountQuery (value = '') {
  if (!value) return
  const matchValue = value.trim()

  if (matchValue === '') {
    return { matchAny: [] }
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
