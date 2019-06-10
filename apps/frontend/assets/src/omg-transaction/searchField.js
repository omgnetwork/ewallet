export const createTransactionQuery = (value = '') => {
  return {
    matchAny: [
      {
        field: 'from_account.id',
        comparator: 'eq',
        value
      },
      {
        field: 'to_account.id',
        comparator: 'eq',
        value
      }
    ]
  }
}
