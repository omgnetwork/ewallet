export const createActionCreator = ({ actionName, action, service }) => async dispatch => {
  dispatch({ type: `${actionName}/${action}/INITIATED` })
  try {
    const result = await service()
    if (result.data.success) {
      return dispatch({
        type: `${actionName}/${action}/SUCCESS`,
        data: result.data.data
      })
    } else {
      return dispatch({ type: `${actionName}/${action}/FAILED`, error: result.data.data })
    }
  } catch (error) {
    console.error('failed to dispatch action', actionName, 'with error', error)
    return dispatch({ type: `${actionName}/${action}/FAILED`, error })
  }
}

export const createPaginationActionCreator = ({ actionName, action, service, cacheKey }) => async dispatch => {
  dispatch({ type: `${actionName}/${action}/INITIATED` })
  try {
    const result = await service()
    if (result.data.success) {
      return dispatch({
        type: `${actionName}/${action}/SUCCESS`,
        data: result.data.data.data,
        pagination: result.data.data.pagination,
        cacheKey
      })
    } else {
      return dispatch({ type: `${actionName}/${action}/FAILED`, error: result.data.data })
    }
  } catch (error) {
    console.error('failed to dispatch paginated action', `[${actionName}]`, 'with error', error)
    return dispatch({ type: `${actionName}/${action}/FAILED`, error })
  }
}
