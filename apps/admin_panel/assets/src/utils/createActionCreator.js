import _ from 'lodash'
import CONSTANT from '../constants'
export const createActionCreator = ({ actionName, action, service }) => async (
  dispatch,
  getState = _.noop,
  injected = {}
) => {
  dispatch({
    type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.INITIATED}`
  })
  try {
    const result = await service(dispatch, getState, injected)
    if (result.data.success) {
      return dispatch({
        type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.SUCCESS}`,
        data: result.data.data
      })
    } else {
      return dispatch({
        type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.FAILED}`,
        error: result.data.data
      })
    }
  } catch (error) {
    console.error('failed to dispatch action', actionName, 'with error', error)
    return dispatch({ type: `${actionName}/${action}/FAILED`, error })
  }
}

export const createPaginationActionCreator = ({
  actionName,
  action,
  service,
  cacheKey
}) => async dispatch => {
  dispatch({
    type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.INITIATED}`
  })
  try {
    const result = await service()
    if (result.data.success) {
      return dispatch({
        type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.SUCCESS}`,
        data: result.data.data.data,
        pagination: result.data.data.pagination,
        cacheKey
      })
    } else {
      return dispatch({
        type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.FAILED}`,
        error: result.data.data
      })
    }
  } catch (error) {
    console.error('failed to dispatch paginated action', `[${actionName}]`, 'with error', error)
    return dispatch({ type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.FAILED}`, error })
  }
}
