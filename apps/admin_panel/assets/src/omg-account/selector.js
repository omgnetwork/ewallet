export const selectAccounts = (state, search) => {
  return _.values(state.accounts)
  .filter(x => {
    const reg = new RegExp(search)
    return reg.test(x.name) || reg.test(x.description)
  })
}
export const selectAccountsLoadingStatus = state => state.accountsLoadingStatus
export const selectGetAccountById = state => id => state.accounts[id]
