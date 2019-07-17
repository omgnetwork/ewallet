export const selectMetamaskUsable = state =>
  !!state.metamask.unlocked && !!state.metamask.enabled
export const selectMetamaskEnabled = state => !!state.metamask.enabled
export const selectCurrentAddress = state => state.metamask.selectedAddress
export const selectNetwork = state => +state.metamask.networkVersion
export const selectBlockchainBalanceByAddressArray = state => address =>
  _.values(selectBlockchainBalanceByAddress(state)(address))

export const selectBlockchainBalanceByAddress = state => address =>
  state.blockchainBalance[address]
