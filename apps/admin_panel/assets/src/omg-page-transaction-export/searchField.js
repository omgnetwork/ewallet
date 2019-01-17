export function createSearchTransactionExportQuery ({ fromDate, toDate }) {
  const query = { matchAll: [] }
  if (fromDate) {
    query.matchAll.push({
      field: 'created_at',
      comparator: 'gte',
      value: fromDate
    })
  }
  if (toDate) {
    query.matchAll.push({
      field: 'created_at',
      comparator: 'lte',
      value: toDate
    })
  }
  return query
}
