export const selectTransactions = (state, search) => {
  return _.values(state.transactions).filter(x => {
    const reg = new RegExp(search)
    return (
      reg.test(x.id) ||
      reg.test(x.status) ||
      reg.test(x.from.token.symbol) ||
      reg.test(x.to.token.symbol)
    )
  })
}

export const selectTransactionsLoadingStatus = state => state.transactionsLoadingStatus
