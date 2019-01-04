export function createSearchTransactionExportQuery ({ fromDate, toDate }) {
  return {
    matchAll: [
      {
        field: 'created_at',
        comparator: 'gte',
        value: fromDate
      },
      {
        field: 'created_at',
        comparator: 'lte',
        value: toDate
      }
    ]
  }
}
