import * as transactionRequestService from '../services/transactionRequestService'

export const getTransactionRequests = ({ page, perPage, search, cacheKey }) => async dispatch => {
  dispatch({ type: 'TRANSACTION_REQUEST/REQUEST/INITIATED' })
  try {
    const result = await transactionRequestService.getTransactionRequests({
      perPage: perPage,
      page,
      sort: { by: 'created_at', dir: 'desc' },
      search
    })
    if (result.data.success) {
      return dispatch({
        type: 'TRANSACTION_REQUESTS/REQUEST/SUCCESS',
        data: result.data.data.data,
        pagination: result.data.data.pagination,
        cacheKey
      })
    } else {
      return dispatch({ type: 'TRANSACTION_REQUEST/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'TRANSACTION_REQUEST/REQUEST/FAILED', error })
  }
}

export const getTransactionRequestById = id => async dispatch => {
  dispatch({ type: 'TRANSACTION_REQUEST/REQUEST/INITIATED' })
  try {
    const result = await transactionRequestService.getTransactionRequestById(id)
    if (result.data.success) {
      return dispatch({
        type: 'TRANSACTION_REQUEST/REQUEST/SUCCESS',
        data: result.data.data
      })
    } else {
      return dispatch({ type: 'TRANSACTION_REQUEST/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'TRANSACTION_REQUEST/REQUEST/FAILED', error })
  }
}

export const consumeTransactionRequest = ({
  idempotencyToken,
  formattedTransactionRequestId,
  correlationId,
  tokenId,
  amount,
  providerUserId,
  address
}) => async dispatch => {
  dispatch({ type: 'TRANSACTION_REQUEST/CONSUME/INITIATED' })
  try {
    const result = await transactionRequestService.consumeTransactionRequest({
      idempotencyToken,
      formattedTransactionRequestId,
      correlationId,
      tokenId,
      amount,
      providerUserId,
      address
    })
    if (result.data.success) {
      return dispatch({
        type: 'TRANSACTION_REQUEST/CONSUME/SUCCESS',
        data: result.data.data
      })
    } else {
      return dispatch({ type: 'TRANSACTION_REQUEST/CONSUME/FAILED', error: result.data.data })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'TRANSACTION_REQUEST/CONSUME/FAILED', error })
  }
}

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
  allowAmountOveride
}) => async dispatch => {
  dispatch({ type: 'TRANSACTION_REQUEST/CREATE/INITIATED' })
  try {
    const result = await transactionRequestService.createTransactionRequest({
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
    })
    if (result.data.success) {
      return dispatch({
        type: 'TRANSACTION_REQUEST/CREATE/SUCCESS',
        data: result.data.data
      })
    } else {
      return dispatch({ type: 'TRANSACTION_REQUEST/CREATE/FAILED', error: result.data.data })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'TRANSACTION_REQUEST/CREATE/FAILED', error })
  }
}

export const getTransactionRequestConsumptions = ({
  perPage,
  page,
  sort,
  search,
  id,
  cacheKey
}) => async dispatch => {
  dispatch({ type: 'TRANSACTION_REQUEST_CONSUMPTION/REQUEST/INITIATED' })
  try {
    const result = await transactionRequestService.getTransactionRequestConsumptions({
      perPage,
      page,
      sort: { by: 'created_at', dir: 'desc' },
      search,
      id
    })
    if (result.data.success) {
      return dispatch({
        type: 'TRANSACTION_REQUEST_CONSUMPTION/REQUEST/SUCCESS',
        data: result.data.data.data,
        pagination: result.data.data.pagination,
        cacheKey
      })
    } else {
      return dispatch({
        type: 'TRANSACTION_REQUEST_CONSUMPTION/REQUEST/FAILED',
        error: result.data.data
      })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'TRANSACTION_REQUEST_CONSUMPTION/REQUEST/FAILED', error })
  }
}
