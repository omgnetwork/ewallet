import * as transactionService from '../services/transactionService'
export const createTransaction = () => async dispatch => {}

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
