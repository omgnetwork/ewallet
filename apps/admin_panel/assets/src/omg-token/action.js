import * as tokenSerivce from '../services/tokenService'
export const createToken = ({ name, symbol, decimal, amount }) => async dispatch => {
  dispatch({ type: 'TOKEN/CREATE/INITIATED' })
  try {
    const result = await tokenSerivce.createToken({
      name,
      symbol,
      decimal,
      amount
    })
    if (result.data.success) {
      dispatch({ type: 'TOKEN/CREATE/SUCCESS', token: result.data.data })
    } else {
      dispatch({ type: 'TOKEN/CREATE/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    return dispatch({ type: 'TOKEN/CREATE/FAILED', error })
  }
}
export const mintToken = ({ id, amount }) => async dispatch => {
  try {
    const result = await tokenSerivce.mintToken({
      id,
      amount
    })
    if (result.data.success) {
      dispatch({ type: 'TOKEN/MINT/SUCCESS', token: result.data.data })
    } else {
      dispatch({ type: 'TOKEN/MINT/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    return dispatch({ type: 'TOKEN/MINT/FAILED', error })
  }
}

export const getTokens = ({ search, page, perPage, cacheKey }) => async dispatch => {
  dispatch({ type: 'TOKENS/REQUEST/INITIATED' })
  try {
    const result = await tokenSerivce.getAllTokens({
      perPage: perPage,
      page,
      sort: { by: 'created_at', dir: 'desc' },
      search
    })
    if (result.data.success) {
      return dispatch({
        type: 'TOKENS/REQUEST/SUCCESS',
        data: result.data.data.data,
        pagination: result.data.data.pagination,
        cacheKey
      })
    } else {
      return dispatch({ type: 'TOKENS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    console.log(error)
    return dispatch({ type: 'TOKENS/REQUEST/FAILED', error })
  }
}
