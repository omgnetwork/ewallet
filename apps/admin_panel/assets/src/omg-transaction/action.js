import * as transactionService from '../services/transactionService'
export const transfer = ({
  fromAddress,
  toAddress,
  tokenId,
  fromTokenId,
  toTokenId,
  fromAmount,
  toAmount,
  amount,
  exchangeAddress
}) => async dispatch => {
  try {
    const result = await transactionService.transfer({
      fromAddress,
      toAddress,
      tokenId,
      fromTokenId,
      toTokenId,
      fromAmount,
      toAmount,
      amount,
      exchangeAddress
    })
    if (result.data.success) {
      return dispatch({ type: 'TRANSACTION/CREATE/SUCCESS', data: result.data.data })
    } else {
      return dispatch({ type: 'TRANSACTION/CREATE/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'TRANSACTION/CREATE/FAILED', error })
  }
}
export const getTransactions = ({ page, search, perPage, cacheKey }) => async dispatch => {
  dispatch({ type: 'TRANSACTIONS/REQUEST/INITIATED' })
  try {
    const result = await transactionService.getAllTransactions({
      perPage: perPage,
      sort: { by: 'created_at', dir: 'desc' },
      search_term: search,
      page
    })
    if (result.data.success) {
      return dispatch({
        type: 'TRANSACTIONS/REQUEST/SUCCESS',
        data: result.data.data.data,
        pagination: result.data.data.pagination,
        cacheKey
      })
    } else {
      return dispatch({ type: 'TRANSACTIONS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'TRANSACTIONS/REQUEST/FAILED', error })
  }
}

export const getTransactionById = id => async dispatch => {
  dispatch({ type: 'TRANSACTION/REQUEST/INITIATED' })
  try {
    const result = await transactionService.getTransactionById(id)
    if (result.data.success) {
      return dispatch({
        type: 'TRANSACTION/REQUEST/SUCCESS',
        data: result.data.data
      })
    } else {
      return dispatch({ type: 'TRANSACTION/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'TRANSACTION/REQUEST/FAILED', error })
  }
}
