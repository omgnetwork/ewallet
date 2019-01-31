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

export const getAccounts = ({ page, perPage, search, cacheKey }) =>
  createPaginationActionCreator({
    actionName: 'ACCOUNTS',
    action: 'REQUEST',
    service: () =>
      accountService.getAllAccounts({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search
      }),
    cacheKey
  })

export const getAccountById = id =>
  createActionCreator({
    actionName: 'ACCOUNT',
    action: 'REQUEST',
    service: () => accountService.getAccountById(id)
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
