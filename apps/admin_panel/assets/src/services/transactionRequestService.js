import { authenticatedRequest } from './apiService'
import uuid from 'uuid/v4'
export function getTransactionRequests ({ perPage, page, sort, search }) {
  return authenticatedRequest({
    path: '/transaction_request.all',
    data: {
      per_page: Number(perPage),
      page: Number(page) || 1,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search
    }
  })
}
export function getTransactionRequestConsumptions ({ perPage, page, sort, search, id }) {
  return authenticatedRequest({
    path: '/transaction_request.get_transaction_consumptions',
    data: {
      formatted_transaction_request_id: id,
      per_page: Number(perPage),
      page: Number(page) || 1,
      sort_by: sort.by,
      sort_dir: sort.dir,
      search_term: search
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
  allowAmountOveride
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
      max_consumption: Number(maxConsumption) || undefined,
      max_consumptionPerUser: Number(maxConsumptionPerUser) || undefined,
      expiration_date: expirationDate,
      allow_amount_overide: allowAmountOveride
    }
  })
}

export function consumeTransactionRequest ({
  formattedTransactionRequestId,
  correlationId,
  tokenId,
  amount,
  providerUserId,
  address
}) {
  return authenticatedRequest({
    path: '/transaction_request.consume',
    data: {
      idempotency_token: uuid(),
      formatted_transaction_request_id: formattedTransactionRequestId,
      correlation_id: correlationId,
      token_id: tokenId,
      amount: Number(amount),
      provider_user_id: providerUserId,
      address
    }
  })
}

export function getTransactionRequestById (id) {
  return authenticatedRequest({
    path: '/transaction_request.get',
    data: { formatted_id: id }
  })
}
