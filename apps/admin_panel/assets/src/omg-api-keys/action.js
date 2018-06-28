import * as apikeyService from '../services/apikeyService'
export const generateApiKey = owner => async dispatch => {
  try {
    const result = await apikeyService.createApikey({ owner })
    if (result.data.success) {
      dispatch({
        type: 'API_KEY/CREATE/SUCCESS',
        apiKey: result.data.data
      })
    } else {
      dispatch({ type: 'API_KEY/CREATE/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    dispatch({ type: 'API_KEY/CREATE/FAILED', error })
  }
}
export const disableApiKey = id => async dispatch => {
  try {
    const result = await apikeyService.deleteApiKeyById(id)
    if (result.data.success) {
      dispatch({
        type: 'API_KEY/DISABLE/SUCCESS',
        apiKey: result.data.data
      })
    } else {
      dispatch({ type: 'API_KEY/DISABLE/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    dispatch({ type: 'API_KEY/DISABLE/FAILED', error })
  }
}
export const updateApiKey = ({ id, expired }) => async dispatch => {
  try {
    const result = await apikeyService.updateApiKey({ id, expired })
    if (result.data.success) {
      dispatch({
        type: 'API_KEY/UPDATE/SUCCESS',
        apiKey: result.data.data
      })
    } else {
      dispatch({ type: 'API_KEY/UPDATE/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    dispatch({ type: 'API_KEY/UPDATE/FAILED', error })
  }
}

export const getApiKeys = ({ page, perPage, search, cacheKey }) => async dispatch => {
  try {
    const result = await apikeyService.getAllApikey({
      perPage,
      page,
      sort: { by: 'created_at', dir: 'desc' },
      search
    })
    if (result.data.success) {
      return dispatch({
        type: 'API_KEY/REQUEST/SUCCESS',
        data: result.data.data.data,
        cacheKey,
        pagination: result.data.data.pagination
      })
    } else {
      return dispatch({ type: 'API_KEY/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    dispatch({ type: 'API_KEY/REQUEST/FAILED', error })
  }
}
