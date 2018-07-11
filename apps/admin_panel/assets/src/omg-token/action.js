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

export const getTokens = ({ search, page, perPage, cacheKey, searchTerms }) =>
  createPaginationActionCreator({
    actionName: 'TOKENS',
    action: 'REQUEST',
    service: () =>
      tokenService.getAllTokens({
        perPage,
        page,
        searchTerms,
        sort: { by: 'created_at', dir: 'desc' },
        search
      }),
    cacheKey
  })

export const getMintedTokenHistory = ({ tokenId, search, page, perPage, searchTerms, cacheKey }) =>
  createPaginationActionCreator({
    actionName: 'TOKEN_HISTORY',
    action: 'REQUEST',
    service: () =>
      tokenService.getMintedTokenHistory({
        perPage,
        page,
        sort: { by: 'created_at', dir: 'desc' },
        search,
        searchTerms,
        tokenId
      }),
    cacheKey
  })

export const getTokenById = id =>
  createActionCreator({
    actionName: 'TOKEN',
    action: 'REQUEST',
    service: () => tokenService.getTokenStatsById(id)
  })
