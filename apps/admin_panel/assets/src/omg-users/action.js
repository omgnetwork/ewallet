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

export const getUsers = () => async dispatch => {
  try {
    const result = await userService.getAllUsers({
      per: 1000,
      sort: { by: 'created_at', dir: 'desc' }
    })

    if (result.data.success) {
      return dispatch({ type: 'USERS/REQUEST/SUCCESS', users: result.data.data.data })
    } else {
      return dispatch({ type: 'USERS/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'USERS/REQUEST/FAILED', error })
  }
}
