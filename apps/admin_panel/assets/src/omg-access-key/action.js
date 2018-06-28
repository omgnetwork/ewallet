import * as accessKeyService from '../services/accessKeyService'
export const generateAccessKey = () => async dispatch => {
  try {
    const result = await accessKeyService.createAccessKey()

    if (result.data.success) {
      return dispatch({
        type: 'ACCESS_KEY/CREATE/SUCCESS',
        data: result.data.data
      })
    } else {
      return dispatch({ type: 'ACCESS_KEY/CREATE/FAILED', error: result.data.data })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'ACCESS_KEY/CREATE/FAILED', error })
  }
}
export const getAccessKeys = () => async dispatch => {
  try {
    const result = await accessKeyService.getAllAccessKey({
      perPage: 1000,
      sort: { by: 'created_at', dir: 'desc' }
    })
    if (result.data.success) {
      return dispatch({
        type: 'ACCESS_KEY/REQUEST/SUCCESS',
        data: result.data.data.data
      })
    } else {
      return dispatch({ type: 'ACCESS_KEY/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'ACCESS_KEY/REQUEST/FAILED', error })
  }
}
