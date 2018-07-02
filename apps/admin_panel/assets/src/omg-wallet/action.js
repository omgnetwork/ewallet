import * as walletService from '../services/walletService'
export const getWalletsByAccountId = ({
  accountId,
  search,
  page,
  perPage,
  cacheKey
}) => async dispatch => {
  dispatch({ type: 'WALLETS/REQUEST/INITIATED' })
  try {
    const result = await walletService.getWalletsByAccountId({
      perPage: perPage,
      sort: { by: 'created_at', dir: 'asc' },
      search_term: search,
      accountId,
      page
    })
    if (result.data.success) {
      return dispatch({
        type: 'WALLETS/REQUEST/SUCCESS',
        data: result.data.data.data,
        pagination: result.data.data.pagination,
        cacheKey
      })
    } else {
      return dispatch({ type: 'WALLETS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'WALLETS/REQUEST/FAILED', error })
  }
}
export const getWalletsByUserId = ({ userId, search }) => async dispatch => {
  dispatch({ type: 'USER_WALLETS/REQUEST/INITIATED' })
  try {
    const result = await walletService.getWalletsByUserId({
      perPage: 1000,
      sort: { by: 'created_at', dir: 'asc' },
      search_term: search,
      userId
    })
    if (result.data.success) {
      return dispatch({ type: 'USER_WALLETS/REQUEST/SUCCESS', data: result.data.data.data })
    } else {
      return dispatch({ type: 'USER_WALLETS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'USER_WALLETS/REQUEST/FAILED', error })
  }
}

export const getWalletById = id => async dispatch => {
  try {
    const result = await walletService.getWallet(id)
    if (result.data.success) {
      dispatch({ type: 'WALLET/REQUEST/SUCCESS', wallet: result.data.data })
    } else {
      dispatch({ type: 'WALLET/REQUEST/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    return dispatch({ type: 'WALLET/REQUEST/FAILED', error })
  }
}
