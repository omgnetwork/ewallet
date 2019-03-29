export const selectAdmin = adminId => state => {
  return state.admins[adminId]
}

export const selectAdminsCachedQuery = state => cacheKey => {
  return _.get(state.cacheQueries[cacheKey], 'ids', []).map(adminId => {
    return selectGetAdminById(state)(adminId)
  })
}

export const selectAdminsLoadingStatus = state => state.loadingStatus.admins

export const selectGetAdminById = state => id => {
  return state.admins[id]
}

