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
