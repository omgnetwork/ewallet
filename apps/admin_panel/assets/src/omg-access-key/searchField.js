export function createSearchAdminKeyQuery (value = '') {
  if (!value) return
  const matchValue = value.trim()
  return {
    matchAny: [
      {
        field: 'name',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'access_key',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}

export function createSearchAdminSubKeyQuery (value = '') {
  if (!value) return
  const matchValue = value.trim()
  return {
    matchAny: [
      {
        field: 'key.name',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'key.access_key',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}
