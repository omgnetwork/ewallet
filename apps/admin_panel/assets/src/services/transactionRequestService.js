import { authenticatedRequest } from './apiService'
import uuid from 'uuid/v4'
export function getTransactionRequests ({ perPage, page, sort, search, matchAll, matchAny }) {
  return authenticatedRequest({
    path: '/transaction_request.all',
    data: {
      per_page: Number(perPage),
      page: Number(page) || 1,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      match_all: matchAll,
      match_any: matchAny
    }
  })
}
export function getTransactionRequestConsumptions ({
  perPage,
  page,
  sort,
  search,
  id,
  searchTerms
}) {
  return authenticatedRequest({
    path: '/transaction_request.get_transaction_consumptions',
    data: {
      formatted_transaction_request_id: id,
      per_page: Number(perPage),
      page: Number(page) || 1,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search,
      search_terms: searchTerms
    }
  })
}
export function createTransactionRequest ({
  type,
  tokenId,
  amount,
  correlationId,
  address,
  accountId,
  providerUserId,
  requireConfirmation,
  maxConsumption,
  maxConsumptionPerUser,
  expirationDate,
  allowAmountOverride,
  consumptionLifetime,
  exchangeAddress
}) {
  return authenticatedRequest({
    path: '/transaction_request.create',
    data: {
      type,
      token_id: tokenId,
      amount: Number(amount) || undefined,
      correlation_id: correlationId,
      address,
      account_id: accountId,
      provider_user_id: providerUserId,
      require_confirmation: requireConfirmation,
      max_consumptions: Number(maxConsumption) || undefined,
      max_consumptions_per_user: Number(maxConsumptionPerUser) || undefined,
      expiration_date: expirationDate,
      allow_amount_override: allowAmountOverride,
      consumption_lifetime: Number(consumptionLifetime) || undefined,
      exchange_wallet_address: exchangeAddress
    }
  })
}

export function consumeTransactionRequest ({
  formattedTransactionRequestId,
  correlationId,
  tokenId,
  amount,
  providerUserId,
  address,
  exchangeAddress
}) {
  return authenticatedRequest({
    path: '/transaction_request.consume',
    data: {
      idempotency_token: uuid(),
      formatted_transaction_request_id: formattedTransactionRequestId,
      correlation_id: correlationId,
      token_id: tokenId,
      amount: amount === null ? null : amount,
      provider_user_id: providerUserId,
      address,
      exchange_wallet_address: exchangeAddress
    }
  })
}

export function getTransactionRequestById (id) {
  return authenticatedRequest({
    path: '/transaction_request.get',
    data: { formatted_id: id }
  })
}
