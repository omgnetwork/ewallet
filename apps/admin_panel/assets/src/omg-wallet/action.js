import * as walletService from '../services/walletService'

export const getWallets = search => async dispatch => {
  dispatch({ type: 'WALLETS/REQUEST/INITIATED' })
  try {
    const result = await walletService.getWallets({
      per: 1000,
      sort: { by: 'created_at', dir: 'asc' },
      search_term: search
    })
    if (result.data.success) {
      return dispatch({ type: 'WALLETS/REQUEST/SUCCESS', wallets: result.data.data.data })
    } else {
      return dispatch({ type: 'WALLETS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'WALLETS/REQUEST/FAILED', error })
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
