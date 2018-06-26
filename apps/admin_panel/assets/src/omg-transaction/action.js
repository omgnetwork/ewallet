import * as transactionService from '../services/transactionService'
export const transfer = ({ fromAddress, toAddress, tokenId, amount }) => async dispatch => {
  try {
    const result = await transactionService.transfer({
      fromAddress,
      toAddress,
      tokenId,
      amount
    })
    if (result.data.success) {
      return dispatch({ type: 'TRANSACTION/CREATE/SUCCESS', transaction: result.data.data })
    } else {
      return dispatch({ type: 'TRANSACTION/CREATE/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'TRANSACTION/CREATE/FAILED', error })
  }
}

export const getTransactions = ({ page, search, perPage }) => async dispatch => {
  dispatch({ type: 'TRANSACTIONS/REQUEST/INITIATED' })
  try {
    const result = await transactionService.getAllTransactions({
      per: perPage,
      sort: { by: 'created_at', dir: 'desc' },
      search_term: search,
      page
    })
    if (result.data.success) {
      return dispatch({ type: 'TRANSACTIONS/REQUEST/SUCCESS', transactions: result.data.data.data })
    } else {
      return dispatch({ type: 'TRANSACTIONS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'TRANSACTIONS/REQUEST/FAILED', error })
  }
}
