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
      dispatch({ type: 'API_KEY/CREATE/FAILED' })
    }
    return result
  } catch (error) {
    dispatch({ type: 'API_KEY/CREATE/FAILED' })
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
      dispatch({ type: 'API_KEY/DISABLE/FAILED' })
    }
    return result
  } catch (error) {
    dispatch({ type: 'API_KEY/DISABLE/FAILED' })
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
      dispatch({ type: 'API_KEY/UPDATE/FAILED' })
    }
    return result
  } catch (error) {
    dispatch({ type: 'API_KEY/UPDATE/FAILED' })
  }
}

export const loadApiKeys = () => async dispatch => {
  try {
    const result = await apikeyService.getAllApikey({
      per: 1000,
      sort: { by: 'created_at', dir: 'desc' }
    })
    if (result.data.success) {
      dispatch({
        type: 'API_KEY/REQUEST/SUCCESS',
        apiKeys: result.data.data.data
      })
    } else {
      dispatch({ type: 'API_KEY/REQUEST/FAILED' })
    }
    return result
  } catch (error) {
    dispatch({ type: 'API_KEY/REQUEST/FAILED' })
  }
}
