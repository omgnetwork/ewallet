import { selectWalletByUserId } from '../omg-wallet/selector'
import { createSelector } from 'reselect'
export const selectUsers = (state, search) => {
  console.log(state)
  return _.values(state.users).filter(x => {
    const reg = new RegExp(search)
    return reg.test(x.id) || reg.test(x.email) || reg.test(x.username)
  })
}
export const selectUser = userId => state => {
  return state.users[userId]
}

export const selectUsersCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(tokenId => {
    return selectGetUserById(state)(tokenId)
  })
}
export const selectUsersAllPagesCachedQuery = state => cacheKey => {
  const query = JSON.parse(cacheKey)
  const allUsersInCache = new Array(query.page).fill().reduce((prev, curr, index) => {
    const newCacheKey = JSON.stringify({ ...query, page: index + 1 })
    const users = _.get(state.cacheQueries[newCacheKey], 'ids', [])
    users.forEach(userId => {
      if (_.findIndex(prev, a => a.id === userId) === -1) {
        prev.push(selectGetUserById(state)(userId))
      }
    })
    return prev
  }, [])
  return allUsersInCache
}
export const selectUsersCachedQueryPagination = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'pagination', {})
}
export const selectUserWithWallet = userId =>
  createSelector(selectUser(userId), selectWalletByUserId(userId), (user, wallet) => {
    return {
      ...user,
      wallet
    }
  })

export const selectUsersLoadingStatus = state => state.usersLoadingStatus
export const selectGetUserById = state => id => state.users[id]
