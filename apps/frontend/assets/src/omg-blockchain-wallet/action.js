import * as blockchainWalletService from '../services/blockchainWalletService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const getBlockchainWalletBalance = ({ address }) =>
  createPaginationActionCreator({
    actionName: 'BLOCKCHAIN_WALLET_BALANCE',
    action: 'REQUEST',
    service: () => blockchainWalletService.getBlockchainWalletBalance(address),
    cacheKey: address
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

export const createBlockchainWallet = ({
  name,
  type,
  address
}) =>
  createActionCreator({
    actionName: 'BLOCKCHAIN_WALLET',
    action: 'CREATE',
    service: () =>
      blockchainWalletService.createBlockchainWallet({
        name,
        type,
        address
      })
  })
