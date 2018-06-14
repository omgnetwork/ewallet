import * as currentUserSerivce from '../services/currentUserService'
import * as adminService from '../services/adminService'
export const getCurrentUser = () => async dispatch => {
  dispatch({ type: 'CURRENT_USER/REQUEST/INITIATED' })
  try {
    const result = await currentUserSerivce.getCurrentUser()
    if (result.data.success) {
      dispatch({ type: 'CURRENT_USER/REQUEST/SUCCESS', currentUser: result.data.data })
    } else {
      dispatch({ type: 'CURRENT_USER/REQUEST/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    return dispatch({ type: 'CURRENT_USER/REQUEST/FAILED', error })
  }
}

export const updateCurrentUser = ({ avatar, email }) => async dispatch => {
  try {
    const resultUpdateCurrentUser = await currentUserSerivce.updateCurrentUser({ email })
    if (resultUpdateCurrentUser.data.success) {
      if (avatar) {
        const userId = resultUpdateCurrentUser.data.data.id
        const resultUploadAvatar = await adminService.uploadAvatar({
          id: userId,
          avatar
        })
        if (resultUploadAvatar.data.success) {
          dispatch({
            type: 'CURRENT_USER/UPDATE/SUCCESS',
            currentUser: resultUploadAvatar.data.data
          })
        } else {
          dispatch({ type: 'CURRENT_USER/UPDATE/FAILED', error: resultUploadAvatar.data.data })
        }
        return resultUploadAvatar
      } else {
        dispatch({
          type: 'CURRENT_USER/UPDATE/SUCCESS',
          currentUser: resultUpdateCurrentUser.data.data
        })
      }
      return resultUpdateCurrentUser
    } else {
      dispatch({ type: 'CURRENT_USER/UPDATE/FAILED', error: resultUpdateCurrentUser.data.data })
    }
    return resultUpdateCurrentUser
  } catch (error) {
    dispatch({ type: 'CURRENT_USER/UPDATE/FAILED', error })
  }
}
