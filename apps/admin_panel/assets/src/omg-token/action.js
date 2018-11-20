import * as tokenService from '../services/tokenService'
import { createActionCreator, createPaginationActionCreator } from '../utils/createActionCreator'
export const createToken = ({ name, symbol, decimal, amount }) =>
  createActionCreator({
    actionName: 'TOKEN',
    action: 'CREATE',
    service: () =>
      tokenService.createToken({
        name,
        symbol,
        decimal,
        amount
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
