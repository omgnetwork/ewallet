import _ from 'lodash'
import { createSelectAllPagesCachedQuery } from '../omg-cache/selector'
import { selectGetAccountById } from '../omg-account/selector'
export const selectWallets = (state, search) => {
  return _.values(state.wallets).filter(wallet => {
    const reg = new RegExp(search)
    return reg.test(wallet.name) || reg.test(wallet.address)
  })
}
export const selectWalletsByAccountId = (state, search, accountId) => {
  return _.values(state.wallets).filter(wallet => {
    const reg = new RegExp(search)
    return wallet.account_id === accountId && (reg.test(wallet.name) || reg.test(wallet.address))
  })
}
export const selectPrimaryWalletByAccountId = state => accountId => {
  if (!accountId) return {}
  return _.values(state.wallets).find(wallet => {
    const account = selectGetAccountById(state)(accountId)
    return wallet.account_id === account.id && wallet.identifier === 'primary'
  })
}
export const selectWalletsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(tokenId => {
    return selectWalletById(state)(tokenId)
  })
}
export const selectWalletsCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}

export const selectWalletsLoadingStatus = state => state.loadingStatus.wallets

export const selectWalletById = state => id => state.wallets[id]
export const selectWalletsByUserId = userId => state => {
  return _.values(state.wallets).find(wallet => {
    return wallet.user_id === userId
  })
}

export const selectNewWallets = state => selectWallets(state).filter(tx => tx.__new)

export const selectWalletsAllPagesCachedQuery = createSelectAllPagesCachedQuery(selectWalletById)
