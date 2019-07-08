import * as blockchainWalletService from '../services/blockchainWalletService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const getBlockchainWalletBalances = ({
  address,
  tokenIds,
  tokenAddresses,
  page,
  perPage,
  cacheKey,
  matchAll,
  matchAny
}) =>
  createPaginationActionCreator({
    actionName: 'BLOCKCHAIN_WALLET_BALANCES',
    action: 'REQUEST',
    service: () =>
      blockchainWalletService.getBlockchainWalletBalances({
        address,
        tokenIds,
        tokenAddresses,
        page,
        perPage,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny
      }),
    cacheKey
  })

export const getBlockchainWallet = (address) =>
  createActionCreator({
    actionName: 'BLOCKCHAIN_WALLET',
    action: 'REQUEST',
    service: () => blockchainWalletService.getBlockchainWallet(address)
  })

export const getAllBlockchainWallets = ({
  page,
  perPage,
  cacheKey,
  matchAll,
  matchAny
}) =>
  createPaginationActionCreator({
    actionName: 'BLOCKCHAIN_WALLETS',
    action: 'REQUEST',
    service: () =>
      blockchainWalletService.getAllBlockchainWallets({
        page,
        perPage,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny
      }),
    cacheKey
  })
