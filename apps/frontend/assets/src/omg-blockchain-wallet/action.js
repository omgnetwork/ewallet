import * as blockchainWalletService from '../services/blockchainWalletService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const getBlockchainWalletBalance = ({
  address,
  tokenIds,
  tokenAddresses,
  page,
  perPage,
  cacheKey,
  matchAll,
  matchAny,
  searchTerm
}) =>
  createPaginationActionCreator({
    actionName: 'BLOCKCHAIN_WALLET_BALANCE',
    action: 'REQUEST',
    service: () =>
      blockchainWalletService.getBlockchainWalletBalance({
        address,
        tokenIds,
        tokenAddresses,
        page,
        perPage,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny,
        searchTerm
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
