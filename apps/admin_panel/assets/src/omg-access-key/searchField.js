export function createSearchAdminKeyQuery (value = '') {
  if (!value) return
  const matchValue = value.trim()
  return {
    matchAny: [
      {
        field: 'name',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}
