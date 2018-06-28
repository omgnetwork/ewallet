export const selectAccessKeys = state =>
  _.sortBy(_.values(state.accessKeys), 'created_at').reverse()
export const selectAccessKeysLoadingStatus = state => state.accessKeysLoadingStatus
