import * as sessionService from '../services/sessionService'
export const login = ({ email, password, rememberMe }) => async dispatch => {
  try {
    const sessionResult = await sessionService.login({ email, password })
    const account = sessionService.getCurrentAccountFromLocalStorage()
    if (sessionResult.data.success) {
      sessionService.setAccessToken(sessionResult.data.data)
      if (!account) sessionService.setCurrentAccount(sessionResult.data.data.account)
      dispatch({
        type: 'LOGIN/SUCCESS',
        currentUser: sessionResult.data.data.user,
        currentAccount: sessionResult.data.data.account
      })
    } else {
      dispatch({ type: 'LOGIN/FAILED' })
    }
    return sessionResult
  } catch (error) {
    console.log(error)
    dispatch({ type: 'LOGIN/FAILED' })
  }
}

export const logout = () => async dispatch => {
  try {
    const sessionResult = await sessionService.logout()
    if (sessionResult.data.success) {
      sessionService.setAccessToken(null)
      dispatch({
        type: 'LOGOUT/SUCCESS'
      })
    } else {
      dispatch({ type: 'LOGOUT/FAILED' })
    }
    return sessionResult
  } catch (error) {
    console.log(error)
    dispatch({ type: 'LOGOUT/FAILED' })
  }
}
export const sendResetPasswordEmail = ({ email, redirectUrl }) => async dispatch => {
  try {
    const result = await sessionService.resetPassword({
      email,
      redirectUrl: `${redirectUrl}?token={token}&email={email}`
    })
    if (result.data.success) {
      dispatch({ type: 'RESET_PASSWORD/SUCCESS' })
    } else {
      dispatch({ type: 'RESET_PASSWORD/FAILED' })
    }
    return result
  } catch (error) {
    dispatch({ type: 'RESET_PASSWORD/FAILED' })
  }
}

export const updatePassword = ({
  resetToken,
  password,
  passwordConfirmation,
  email
}) => async dispatch => {
  try {
    const result = await sessionService.updatePassword({
      resetToken,
      password,
      passwordConfirmation,
      email
    })
    if (result.data.success) {
      dispatch({ type: 'UPDATE_PASSWORD/SUCCESS' })
    } else {
      dispatch({ type: 'UPDATE_PASSWORD/FAILED' })
    }
    return result
  } catch (error) {
    dispatch({ type: 'UPDATE_PASSWORD/FAILED' })
  }
}
