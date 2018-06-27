export const selectCacheQueriesByEntity = entity => state => {
  return _.keys(state.cacheQueries).reduce((prev, curr) => {
    const keyObj = JSON.parse(curr)
    if (keyObj.entity === entity) {
      prev.push(curr)
    }
    return prev
  }, [])
}

export const createSelectAllPagesCachedQuery = selectGetSelector => {
  return state => cacheKey => {
    const query = JSON.parse(cacheKey)
    const cacheData = new Array(query.page).fill().reduce((prev, curr, index) => {
      const newCacheKey = JSON.stringify({ ...query, page: index + 1 })
      const accounts = _.get(state.cacheQueries[newCacheKey], 'ids', [])
      accounts.forEach(accountId => {
        if (_.findIndex(prev, a => a.id === accountId) === -1) {
          prev.push(selectGetSelector(state)(accountId))
        }
      })
      return prev
    }, [])
    return cacheData
  }
}
