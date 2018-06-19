import * as transactionService from '../services/transactionService'
export const createTransaction = ({
  fromAddress,
  toAddress,
  tokenId,
  amount
}) => async dispatch => {
  try {
    const result = await transactionService.createTransaction({
      fromAddress,
      toAddress,
      tokenId,
      amount
    })
    if (result.data.success) {
      dispatch({ type: 'TRANSACTION/CREATE/SUCCESS', transaction: result.data.data })
    } else {
      dispatch({ type: 'TRANSACTION/CREATE/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    return dispatch({ type: 'TRANSACTION/CREATE/FAILED', error })
  }
}

export const getTransactions = search => async dispatch => {
  dispatch({ type: 'TRANSACTIONS/REQUEST/INITIATED' })
  try {
    const result = await transactionService.getAllTransactions({
      per: 1000,
      sort: { by: 'created_at', dir: 'desc' },
      search_term: search
    })
    if (result.data.success) {
      return dispatch({ type: 'TRANSACTIONS/REQUEST/SUCCESS', transactions: result.data.data })
    } else {
      return dispatch({ type: 'TRANSACTIONS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'TRANSACTIONS/REQUEST/FAILED', error })
  }
}
