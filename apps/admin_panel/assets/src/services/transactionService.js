import { authenticatedRequest } from './apiService'

export function getAllTransactions ({ per, sort, query, ...rest }) {
  return authenticatedRequest({
    path: '/transaction.all',
    data: {
      per_page: per,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: query,
      ...rest
    }
  })
}

export function createTransaction (params, callback) {
  // not sure what is this yet
  callback(null, { id: 1234 })
}

export function getTransactionById (id) {
  return authenticatedRequest({
    path: '/transaction.get',
    data: { id }
  })
}
