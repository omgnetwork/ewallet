import * as tokenService from '../services/tokenService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'

export const createBlockchainToken = ({ name, symbol, decimal, amount, locked }) =>
  createActionCreator({
    actionName: 'TOKEN',
    action: 'CREATE',
    service: () =>
      tokenService.createBlockchainToken({
        name,
        symbol,
        decimal,
        amount,
        locked
      })
  })

export const createToken = ({ name, symbol, decimal, amount, blockchain_address }) =>
  createActionCreator({
    actionName: 'TOKEN',
    action: 'CREATE',
    service: () =>
      tokenService.createToken({
        name,
        symbol,
        decimal,
        amount,
        blockchain_address
      })
  })

export const mintToken = ({ id, amount }) =>
  createActionCreator({
    actionName: 'TOKEN',
    action: 'MINT',
    service: () =>
      tokenService.mintToken({
        id,
        amount
      })
  })

export const getTokens = ({ page, perPage, cacheKey, matchAll, matchAny }) =>
  createPaginationActionCreator({
    actionName: 'TOKENS',
    action: 'REQUEST',
    service: () =>
      tokenService.getAllTokens({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        matchAll,
        matchAny
      }),
    cacheKey
  })

export const getMintedTokenHistory = ({ tokenId, search, page, perPage, cacheKey, matchAll, matchAny }) =>
  createPaginationActionCreator({
    actionName: 'TOKEN_HISTORY',
    action: 'REQUEST',
    service: () =>
      tokenService.getMintedTokenHistory({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        tokenId,
        matchAll,
        matchAny
      }),
    cacheKey
  })

export const getTokenById = id =>
  createActionCreator({
    actionName: 'TOKEN',
    action: 'REQUEST',
    service: () => tokenService.getTokenStatsById(id)
  })

export const getErc20Capabilities = address =>
  createActionCreator({
    actionName: 'TOKEN_CAPABILITIES',
    action: 'REQUEST',
    params: { address },
    service: () => tokenService.getErc20Capabilities(address)
  })
