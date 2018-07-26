import * as walletService from '../services/walletService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'
export const getWalletsByAccountId = ({ accountId, search, page, perPage, cacheKey, owned = true }) =>
  createPaginationActionCreator({
    actionName: 'WALLETS',
    action: 'REQUEST',
    service: async () =>
      walletService.getWalletsByAccountId({
        perPage: perPage,
        sort: { by: 'created_at', dir: 'desc' },
        search,
        accountId,
        page,
        owned
      }),
    cacheKey
  })

export const getWallets = ({ search, page, perPage, cacheKey }) =>
  createPaginationActionCreator({
    actionName: 'WALLETS',
    action: 'REQUEST',
    service: async () =>
      walletService.getWallets({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search
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
