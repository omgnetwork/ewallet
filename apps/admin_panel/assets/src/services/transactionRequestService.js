import { authenticatedRequest } from './apiService'
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
      amount,
      correlation_id: correlationId,
      address,
      account_id: accountId,
      provider_user_id: providerUserId,
      require_confirmation: requireConfirmation,
      max_consumption: maxConsumption,
      max_consumptionPerUser: maxConsumptionPerUser,
      expiration_date: expirationDate,
      allow_amount_overide: allowAmountOveride
    }
  })
}

export function consumeTransactionRequest ({
  idempotency_token,
  formatted_transaction_request_id,
  correlation_id,
  token_id,
  amount,
  provider_user_id,
  address
}) {
  return authenticatedRequest({
    path: '/transaction_request.consume',
    data: {
      idempotency_token,
      formatted_transaction_request_id,
      correlation_id,
      token_id,
      amount,
      provider_user_id,
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
