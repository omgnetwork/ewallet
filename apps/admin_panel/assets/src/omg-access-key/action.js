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
export const getAccessKeys = ({ page, perPage, search, cacheKey }) => async dispatch => {
  try {
    const result = await accessKeyService.getAllAccessKey({
      perPage,
      page,
      sort: { by: 'created_at', dir: 'desc' },
      search
    })
    if (result.data.success) {
      return dispatch({
        type: 'ACCESS_KEY/REQUEST/SUCCESS',
        data: result.data.data.data,
        pagination: result.data.data.pagination,
        cacheKey
      })
    } else {
      return dispatch({ type: 'ACCESS_KEY/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'ACCESS_KEY/REQUEST/FAILED', error })
  }
}
