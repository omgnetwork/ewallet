import { authenticatedRequest } from './apiService'
import uuid from 'uuid/v4'
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

export function transfer ({ fromAddress, toAddress, tokenId, amount }) {
  return authenticatedRequest({
    path: '/transfer',
    data: {
      from_address: fromAddress,
      to_address: toAddress,
      token_id: tokenId,
      amount,
      idempotency_token: uuid()
    }
  })
}

export function getTransactionById (id) {
  return authenticatedRequest({
    path: '/transaction.get',
    data: { id }
  })
}
