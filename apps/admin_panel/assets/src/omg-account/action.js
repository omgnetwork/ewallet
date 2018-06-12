import * as accountService from '../services/accountService'
export const createAccount = ({ name, description, avatar, category }) => async dispatch => {
  try {
    const resultCreateAccount = await accountService.createAccount({ name, description, category })
    if (resultCreateAccount.data.success) {
      if (avatar) {
        const accountId = resultCreateAccount.data.data.id
        const resultUploadAvatar = await accountService.uploadAccountAvatar({
          accountId,
          avatar
        })
        if (resultUploadAvatar.data.success) {
          dispatch({ type: 'ACCOUNT/CREATE/SUCCESS', account: resultUploadAvatar.data.data })
        } else {
          dispatch({ type: 'ACCOUNT/CREATE/FAILED', error: resultUploadAvatar.data.data })
        }
        return resultUploadAvatar
      } else {
        dispatch({ type: 'ACCOUNT/CREATE/SUCCESS', account: resultCreateAccount.data.data })
      }
      return resultCreateAccount
    } else {
      dispatch({ type: 'ACCOUNT/CREATE/FAILED', error: resultCreateAccount.data.data })
    }
    return resultCreateAccount
  } catch (error) {
    dispatch({ type: 'ACCOUNT/CREATE/FAILED', error })
  }
}

export const getAccounts = search => async dispatch => {
  // dispatch({ type: 'ACCOUNTS/REQUEST/INITIATED' })
  try {
    const result = await accountService.getAllAccounts({
      per: 100,
      sort: { by: 'created_at', dir: 'desc' },
      search_term: search
    })
    if (result.data.success) {
      return dispatch({ type: 'ACCOUNTS/REQUEST/SUCCESS', accounts: result.data.data })
    } else {
      return dispatch({ type: 'ACCOUNTS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'ACCOUNTS/REQUEST/FAILED', error })
  }
}
