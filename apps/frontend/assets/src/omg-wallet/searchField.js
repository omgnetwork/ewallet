export function createSearchAddressQuery (value = '') {
  const matchValue = value && value.trim()
  if (!matchValue) {
    return {
      matchAny: [],
      matchAll: [
        { field: 'account.name', comparator: 'neq', value: 'genesis' }
      ]
    }
  }

  return {
    matchAll: [
      { field: 'account.name', comparator: 'neq', value: 'genesis' }
    ],
    matchAny: [
      {
        field: 'address',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'account.name',
        comparator: 'contains',
        value: matchValue
      },
      {
        field: 'name',
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
