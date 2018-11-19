export function createSearchInviteQuery (value = '') {
  const matchValue = value.trim()
  return {
    matchAny: [
      {
        field: 'user.id',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'user.username',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'user.email',
        comparator: 'contains',
        value: matchValue
      }
    ]
  }
}
