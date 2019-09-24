import * as blockchainWalletService from '../services/blockchainWalletService'
import { createActionCreator, createPaginationActionCreator, createPaginationMultiPromiseActionCreator } from '../utils/createActionCreator'

export const getBlockchainWalletBalance = ({ address, cacheKey, page, perPage, matchAll, matchAny }) =>
  createPaginationMultiPromiseActionCreator({
    actionName: 'BLOCKCHAIN_WALLET_BALANCE',
    action: 'REQUEST',
    services: () => {
      const params = {
        address,
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny
      }
      const rootPromise = blockchainWalletService.getBlockchainWalletBalance(params)
      const plasmaPromise = blockchainWalletService.getBlockchainWalletPlasmaBalance(params)
      return Promise.all([ rootPromise, plasmaPromise ])
    },
    cacheKey
  })

export const getBlockchainWallet = address =>
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

export const plasmaDeposit = ({
  address,
  amount,
  tokenId
}) =>
  createActionCreator({
    actionName: 'BLOCKCHAIN_WALLET',
    action: 'DEPOSIT',
    service: () =>
      blockchainWalletService.plasmaDeposit({
        address,
        amount,
        tokenId
      })
  })
