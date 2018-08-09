import * as transactionRequestService from '../services/transactionRequestService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'
export const getTransactionRequests = ({ page, perPage, search, cacheKey }) =>
  createPaginationActionCreator({
    actionName: 'TRANSACTION_REQUESTS',
    action: 'REQUEST',
    service: () =>
      transactionRequestService.getTransactionRequests({
        perPage: perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search
      }),
    cacheKey
  })

export const getTransactionRequestById = id =>
  createActionCreator({
    actionName: 'TRANSACTION_REQUEST',
    action: 'REQUEST',
    service: () => transactionRequestService.getTransactionRequestById(id)
  })

export const consumeTransactionRequest = ({
  formattedTransactionRequestId,
  correlationId,
  tokenId,
  amount,
  providerUserId,
  address,
  exchangeAddress
}) =>
  createActionCreator({
    actionName: 'TRANSACTION_REQUEST',
    action: 'CONSUME',
    service: () =>
      transactionRequestService.consumeTransactionRequest({
        formattedTransactionRequestId,
        correlationId,
        tokenId,
        amount,
        providerUserId,
        address,
        exchangeAddress
      })
  })

export const createTransactionRequest = ({
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
}) =>
  createActionCreator({
    actionName: 'TRANSACTION_REQUEST',
    action: 'CREATE',
    service: () =>
      transactionRequestService.createTransactionRequest({
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
      })
  })

export const getTransactionRequestConsumptions = ({
  perPage,
  page,
  sort,
  search,
  id,
  cacheKey,
  searchTerms
}) =>
  createPaginationActionCreator({
    actionName: 'TRANSACTION_REQUEST_CONSUMPTION',
    action: 'REQUEST',
    service: () =>
      transactionRequestService.getTransactionRequestConsumptions({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search,
        id,
        searchTerms
      }),
    cacheKey
  })
