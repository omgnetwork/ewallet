export function createSearchUsersQuery (value = '') {
  const matchValue = value.trim()
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
