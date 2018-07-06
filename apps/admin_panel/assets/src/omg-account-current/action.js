import { setCurrentAccount } from '../services/sessionService'
import * as settingService from '../services/settingService'
import * as accountService from '../services/accountService'
export const loadCurrentAccount = accountId => async (dispatch, getState, { socket }) => {
  dispatch({ type: 'CURRENT_ACCOUNT/REQUEST/INITIATED' })
  try {
    const result = await accountService.getAccountById(accountId)
    if (result.data.success) {
      socket.joinChannel(`account:${result.data.data.id}`)
      dispatch({ type: 'CURRENT_ACCOUNT/REQUEST/SUCCESS', currentAccount: result.data.data })
    } else {
      dispatch({ type: 'CURRENT_ACCOUNT/REQUEST/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    console.log('Failed to load current account with error', error)
    return dispatch({ type: 'CURRENT_ACCOUNT/REQUEST/FAILED', error })
  }
}

const uploadAvatar = ({ avatar, accountId }) => async dispatch => {
  const resultUploadAvatar = await accountService.uploadAccountAvatar({
    accountId,
    avatar
  })
  if (resultUploadAvatar.data.success) {
    dispatch({
      type: 'CURRENT_ACCOUNT/UPDATE/SUCCESS',
      currentAccount: resultUploadAvatar.data.data
    })
  } else {
    dispatch({ type: 'CURRENT_ACCOUNT/UPDATE/FAILED', error: resultUploadAvatar.data.data })
  }
  return resultUploadAvatar
}
export const updateCurrentAccount = ({ accountId, name, description, avatar }) => async dispatch => {
  try {
    const resultUpdateAccount = await settingService.updateAccountInfo({
      id: accountId,
      name,
      description
    })
    if (resultUpdateAccount.data.success) {
      if (!avatar) {
        dispatch({
          type: 'CURRENT_ACCOUNT/UPDATE/SUCCESS',
          currentAccount: resultUpdateAccount.data.data
        })
        return resultUpdateAccount
      }
      const resultUploadAvatar = await uploadAvatar({ accountId, avatar })(dispatch)
      return resultUploadAvatar
    } else {
      dispatch({ type: 'CURRENT_ACCOUNT/UPDATE/FAILED', error: resultUpdateAccount.data.data })
    }
  } catch (error) {
    console.log(error)
    dispatch({ type: 'CURRENT_ACCOUNT/UPDATE/FAILED', error })
  }
}

export const switchAccount = accountToSwitch => (dispatch, getState, { socket }) => {
  setCurrentAccount(accountToSwitch)
  socket.leaveChannel(`account:${getState().currentAccount.id}`)
  socket.joinChannel(`account:${accountToSwitch.id}`)
  return dispatch({ type: 'CURRENT_ACCOUNT/SWITCH', currentAccount: accountToSwitch })
}
