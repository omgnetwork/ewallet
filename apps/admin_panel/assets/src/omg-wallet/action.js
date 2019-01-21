import * as walletService from '../services/walletService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const getWallets = ({ search, page, perPage, cacheKey, matchAll, matchAny }) =>
  createPaginationActionCreator({
    actionName: 'WALLETS',
    action: 'REQUEST',
    service: async () =>
      walletService.getWallets({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny
      }),
    cacheKey
  })
export const getWalletsAndUserWalletsByAccountId = ({ accountId, page, perPage, cacheKey, owned = false, matchAll, matchAny }) =>
  createPaginationActionCreator({
    actionName: 'WALLETS',
    action: 'REQUEST',
    service: async () =>
      walletService.getWalletsAndUserWalletsByAccountId({
        perPage,
        sort: { by: 'created_at', dir: 'desc' },
        accountId,
        page,
        owned,
        matchAll,
        matchAny
      }),
    cacheKey
  })
export const getWalletsByAccountId = ({ accountId, page, perPage, cacheKey, owned = true, matchAll, matchAny }) =>
  createPaginationActionCreator({
    actionName: 'WALLETS',
    action: 'REQUEST',
    service: async () =>
      walletService.getWalletsByAccountId({
        perPage,
        sort: { by: 'identifier', dir: 'desc' },
        accountId,
        page,
        owned,
        matchAll,
        matchAny
      }),
    cacheKey
  })
export const getWalletsByUserId = ({ userId, perPage, search, page, cacheKey }) =>
  createPaginationActionCreator({
    actionName: 'USER_WALLETS',
    action: 'REQUEST',
    service: async () =>
      walletService.getWalletsByUserId({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search,
        userId
      }),
    cacheKey
  })

export const getWalletById = id =>
  createActionCreator({
    actionName: 'WALLET',
    action: 'REQUEST',
    service: async () => walletService.getWallet(id)
  })
