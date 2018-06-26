import * as userService from '../services/userService'
export const createUser = ({ name, description, avatar }) => async dispatch => {
  try {
    const resultCreateUser = await userService.createUser({ name, description })
    if (resultCreateUser.data.success) {
      dispatch({ type: 'USER/CREATE/SUCCESS', user: resultCreateUser.data.data })
    } else {
      dispatch({ type: 'USER/CREATE/FAILED', error: resultCreateUser.data.data })
    }
    return resultCreateUser
  } catch (error) {
    dispatch({ type: 'USER/CREATE/FAILED', error })
  }
}

export const getUsers = ({ search, page, perPage }) => async dispatch => {
  dispatch({ type: 'USERS/REQUEST/INITIATED' })
  try {
    const result = await userService.getAllUsers({
      per: perPage,
      page,
      sort: { by: 'created_at', dir: 'desc' },
      search_term: search
    })

    if (result.data.success) {
      return dispatch({
        type: 'USERS/REQUEST/SUCCESS',
        users: result.data.data.data,
        pagination: result.data.data.pagination
      })
    } else {
      return dispatch({ type: 'USERS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'USERS/REQUEST/FAILED', error })
  }
}

export const getUserById = id => async dispatch => {
  try {
    const result = await userService.getUserById(id)
    if (result.data.success) {
      dispatch({ type: 'USER/REQUEST/SUCCESS', user: result.data.data })
    } else {
      dispatch({ type: 'USER/REQUEST/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    return dispatch({ type: 'USER/REQUEST/FAILED', error })
  }
}
