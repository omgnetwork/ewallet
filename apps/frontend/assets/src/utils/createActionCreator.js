import _ from 'lodash'
import CONSTANT from '../constants'
export const createActionCreator = ({ actionName, action, service, params }) => async (
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
        data: result.data.data,
        params
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

// Type for services: Promise<[resolves]>
// we take pagination data from the first promise
export const createPaginationMultiPromiseActionCreator = ({
  actionName,
  action,
  services,
  cacheKey
}) => async dispatch => {
  dispatch({
    type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.INITIATED}`
  })
  try {
    const result = await services()
    const allSuccess = _.every(result, ['data.success', true])
    const data = result.map(res => res.data.data.data)

    if (allSuccess) {
      return dispatch({
        type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.SUCCESS}`,
        pagination: result[0].data.data.pagination,
        data,
        cacheKey
      })
    } else {
      const failedPromises = result.filter(res => !res.data.success)
      const errors = failedPromises.map(res => res.data.data)

      return dispatch({
        type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.FAILED}`,
        errors
      })
    }
  } catch (error) {
    console.error('failed to dispatch paginated action', `[${actionName}]`, 'with error', error)
    return dispatch({ type: `${actionName}/${action}/${CONSTANT.LOADING_STATUS.FAILED}`, error })
  }
}
