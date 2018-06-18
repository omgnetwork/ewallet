import { selectWalletByUserId } from '../omg-wallet/selector'
import { createSelector } from 'reselect'
export const selectUsers = (state, search) => {
  return _.values(state.users).filter(x => {
    const reg = new RegExp(search)
    return reg.test(x.id) || reg.test(x.email) || reg.test(x.username)
  })
}
export const selectUser = userId => state => {
  return state.users[userId]
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
