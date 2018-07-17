import * as accountService from '../services/accountService'
import * as adminService from '../services/adminService'
export const inviteMember = ({ email, redirectUrl, accountId, role }) => async dispatch => {
  try {
    const result = await accountService.inviteMember({
      email,
      redirectUrl: `${redirectUrl}?token={token}&email={email}`,
      accountId,
      role
    })
    if (result.data.success) {
      dispatch({ type: 'INVITE/REQUEST/SUCCESS' })
    } else {
      dispatch({ type: 'INVITE/REQUEST/FAILED', error: result.data.data })
    }
    return result
  } catch (error) {
    return dispatch({ type: 'INVITE/REQUEST/FAILED', error })
  }
}

export const getListMembers = accountId => async dispatch => {
  dispatch({ type: 'INVITE_LIST/REQUEST/INITIATED' })
  try {
    const result = await accountService.listMembers({ accountId })
    if (result.data.success) {
      return dispatch({ type: 'INVITE_LIST/REQUEST/SUCCESS', inviteList: result.data.data })
    } else {
      return dispatch({ type: 'INVITE_LIST/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'INVITE_LIST/REQUEST/FAILED', error })
  }
}

export const createUser = ({
  resetToken,
  password,
  passwordConfirmation,
  email
}) => async dispatch => {
  try {
    const result = await adminService.createAdmin({
      resetToken,
      password,
      passwordConfirmation,
      email
    })
    if (result.data.success) {
      dispatch({ type: 'INVITE/CREATE/SUCCESS' })
    } else {
      dispatch({ type: 'INVITE/CREATE/FAILED' })
    }
    return result
  } catch (error) {
    dispatch({ type: 'INVITE/CREATE/FAILED' })
  }
}
