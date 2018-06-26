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

<<<<<<< HEAD
export const getAccounts = ({ page, perPage, search, cacheKey }) => async dispatch => {
  dispatch({ type: 'ACCOUNTS/REQUEST/INITIATED' })

=======
export const getAccounts = search => async dispatch => {
  dispatch({ type: 'ACCOUNTS/REQUEST/INITIATED' })
>>>>>>> develop
  try {
    const result = await accountService.getAllAccounts({
      perPage: perPage,
      page,
      sort: { by: 'created_at', dir: 'desc' },
      search_term: search
    })
    if (result.data.success) {
      return dispatch({
        type: 'ACCOUNTS/REQUEST/SUCCESS',
        data: result.data.data.data,
        pagination: result.data.data.pagination,
        cacheKey
      })
    } else {
      return dispatch({ type: 'ACCOUNTS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'ACCOUNTS/REQUEST/FAILED', error })
  }
}
