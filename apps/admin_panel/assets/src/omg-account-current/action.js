import { setCurrentAccount } from '../services/sessionService'
import * as accountService from '../services/accountService'
import { createActionCreator } from '../utils/createActionCreator'
export const getCurrentAccount = accountId =>
  createActionCreator({
    actionName: 'CURRENT_ACCOUNT',
    action: 'REQUEST',
    service: async (dispatch, getState, { socket }) => {
      try {
        socket.joinChannel(`account:${accountId}`)
      } catch (error) {
        console.warn('cannot join channel from action', '[CURRENT_ACCOUNT]')
        return accountService.getAccountById(accountId)
      }
      return accountService.getAccountById(accountId)
    }
  })

export const uploadAvatar = ({ avatar, accountId }) =>
  createActionCreator({
    actionName: 'CURRENT_ACCOUNT_AVATAR',
    action: 'UPDATE',
    service: () =>
      accountService.uploadAccountAvatar({
        accountId,
        avatar
      })
  })

export const updateCurrentAccount = ({ accountId, name, description, avatar }) =>
  createActionCreator({
    actionName: 'CURRENT_ACCOUNT',
    action: 'UPDATE',
    service: async dispatch => {
      const updatedAccount = await accountService.updateAccountInfo({
        id: accountId,
        name,
        description
      })
      if (updatedAccount.data.success && avatar) {
        const result = await accountService.uploadAccountAvatar({
          accountId,
          avatar
        })
        return result
      }
      return updatedAccount
    }
  })

export const switchAccount = accountToSwitch => (dispatch, getState, { socket }) => {
  setCurrentAccount(accountToSwitch)
  socket.leaveChannel(`account:${getState().currentAccount.id}`)
  socket.joinChannel(`account:${accountToSwitch.id}`)
  return dispatch({ type: 'CURRENT_ACCOUNT/SWITCH', data: accountToSwitch })
}
