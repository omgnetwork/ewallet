import { createPaginationActionCreator, createActionCreator } from '../utils/createActionCreator'
import * as accountService from '../services/accountService'

export const createAccount = ({ name, description, avatar, category }) =>
  createActionCreator({
    actionName: 'ACCOUNT',
    action: 'CREATE',
    service: async () => {
      const account = await accountService.createAccount({ name, description, category })
      if (avatar) {
        const uploadedAvatarAccount = await accountService.uploadAccountAvatar({
          accountId: account.data.data.id,
          avatar
        })
        return uploadedAvatarAccount
      }
      return account
    }
  })

export const getAccounts = ({ page, perPage, search, cacheKey, matchAny }) =>
  createPaginationActionCreator({
    actionName: 'ACCOUNTS',
    action: 'REQUEST',
    service: () =>
      accountService.getAllAccounts({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search,
        matchAny
      }),
    cacheKey
  })

export const getKeysAccountId = ({
  accountId,
  page,
  perPage,
  search,
  cacheKey,
  matchAll,
  matchAny
}) =>
  createPaginationActionCreator({
    actionName: 'ACCOUNT_KEY_MEMBERSHIPS',
    action: 'REQUEST',
    service: () =>
      accountService.getKeysByAccountId({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny,
        accountId
      }),
    cacheKey
  })

export const getAccountById = id =>
  createActionCreator({
    actionName: 'ACCOUNT',
    action: 'REQUEST',
    service: () => accountService.getAccountById(id)
  })

export const deleteAccount = id => dispatch => {
  return dispatch({ type: 'ACCOUNT/DELETE', data: id })
}

export const unassignKey = ({ keyId, accountId }) =>
  createActionCreator({
    actionName: 'ACCOUNT',
    action: 'UNASSIGN_KEY',
    params: { keyId, accountId },
    service: () => accountService.unassignKey({ keyId, accountId })
  })

export const assignKey = ({ keyId, role, accountId }) =>
  createActionCreator({
    actionName: 'ACCOUNT',
    action: 'ASSIGN_KEY',
    params: { keyId, role, accountId },
    service: () => accountService.assignKey({ keyId, role, accountId })
  })

export const getConsumptionsByAccountId = ({
  page,
  perPage,
  search,
  cacheKey,
  searchTerms,
  matchAll,
  matchAny,
  accountId
}) =>
  createPaginationActionCreator({
    actionName: 'CONSUMPTIONS',
    action: 'REQUEST',
    service: () =>
      accountService.getConsumptionsByAccountId({
        accountId,
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search,
        searchTerms,
        matchAll,
        matchAny
      }),
    cacheKey
  })

export const getUsersByAccountId = ({ accountId, page, perPage, cacheKey, matchAll, matchAny }) =>
  createPaginationActionCreator({
    actionName: 'USERS',
    action: 'REQUEST',
    service: () =>
      accountService.getUsersByAccountId({
        accountId,
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny
      }),
    cacheKey
  })

export const updateAccount = ({ accountId, name, description, avatar, categoryIds }) =>
  createActionCreator({
    actionName: 'ACCOUNT',
    action: 'UPDATE',
    service: async dispatch => {
      const updatedAccount = await accountService.updateAccountInfo({
        id: accountId,
        name,
        description,
        categoryIds
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

export const subscribeToWebsocketByAccountId = accountid => (dispatch, getState, { socket }) => {
  const state = getState()
  if (state.currentUser) {
    socket.joinChannel(`account:${accountid}`)
    return dispatch({ type: 'SOCKET/ACCOUNT/SUBSCRIBE', accountid })
  }
}
