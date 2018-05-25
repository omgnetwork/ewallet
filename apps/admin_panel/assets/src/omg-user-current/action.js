import * as currentUserSerivce from '../services/currentUserService'
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
