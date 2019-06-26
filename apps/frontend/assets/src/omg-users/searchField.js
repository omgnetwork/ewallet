export function createSearchUsersQuery (value = '') {
  if (!value) return
  const matchValue = value.trim()

  if (matchValue) {
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

  return {
    matchAny: []
  }
}
