import { authenticatedRequest } from './apiService'
import uuid from 'uuid/v4'
export function getAllTransactions ({ page, perPage, sort, search, searchTerms }) {
  return authenticatedRequest({
    path: '/transaction.all',
    data: {
      page,
      per_page: perPage,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      search_terms: searchTerms
    }
  })
}

export function transfer ({ fromAddress, toAddress, tokenId, fromTokenId, toTokenId, fromAmount, toAmount, amount, exchangeAddress }) {
  return authenticatedRequest({
    path: '/transaction.create',
    data: {
      from_address: fromAddress,
      to_address: toAddress,
      token_id: tokenId,
      from_token_id: fromTokenId,
      to_token_id: toTokenId,
      from_amount: fromAmount,
      to_amount: toAmount,
      amount,
      exchange_wallet_address: exchangeAddress,
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
