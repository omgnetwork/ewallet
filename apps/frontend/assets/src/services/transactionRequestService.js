import uuid from 'uuid/v4'
import numeral from 'numeral'

import { authenticatedRequest } from './apiService'

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
  exchangeAddress,
  maxConsumptionPerIntervalPerUser,
  maxConsumptionPerInterval,
  consumptionIntervalDuration
}) {
  return authenticatedRequest({
    path: '/transaction_request.create',
    data: {
      type,
      token_id: tokenId,
      amount: numeral(amount).value() || undefined,
      correlation_id: correlationId,
      address,
      account_id: accountId,
      provider_user_id: providerUserId,
      require_confirmation: requireConfirmation,
      max_consumptions: numeral(maxConsumption).value() || undefined,
      max_consumptions_per_user: numeral(maxConsumptionPerUser).value() || undefined,
      expiration_date: expirationDate,
      allow_amount_override: allowAmountOverride,
      consumption_lifetime: numeral(consumptionLifetime).value() || undefined,
      exchange_wallet_address: exchangeAddress,
      max_consumptions_per_interval_per_user: numeral(maxConsumptionPerIntervalPerUser).value() || undefined,
      max_consumptions_per_interval: numeral(maxConsumptionPerInterval).value() || undefined,
      consumption_interval_duration: numeral(consumptionIntervalDuration).value() || undefined
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

export function cancelTransactionRequestById (id) {
  return authenticatedRequest({
    path: '/transaction_request.cancel',
    data: { formatted_id: id }
  })
}
