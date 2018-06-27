export const selectCacheQueriesByEntity = entity => state => {
  return _.keys(state.cacheQueries).reduce((prev, curr) => {
    const keyObj = JSON.parse(curr)
    if (keyObj.entity === entity) {
      prev.push(curr)
    }
    return prev
  }, [])
}
