export const selectMetamaskEnabled = state => !!state.metamask.unlocked && !!state.metamask.enabled
export const selectCurrentAddress = state => state.metamask.selectedAddress
