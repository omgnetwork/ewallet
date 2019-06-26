export function createSearchUsersQuery (value = '') {
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
        field: 'email',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'username',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}
