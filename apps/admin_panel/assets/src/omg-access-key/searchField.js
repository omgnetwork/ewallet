export function createSearchAdminKeyQuery (value = '') {
  if (!value) return
  const matchValue = value.trim()
  return {
    matchAny: [
      {
        field: 'id',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}
