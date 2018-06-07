import * as settingService from '../services/settingService'
export const inviteMember = ({ email, redirectUrl, accountId, role }) => async dispatch => {
  try {
    const result = await settingService.inviteMember({
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
    console.log(error)
    return dispatch({ type: 'INVITE/REQUEST/FAILED', error })
  }
}

export const getListMembers = accountId => async dispatch => {
  dispatch({ type: 'INVITE_LIST/REQUEST/INITIATED' })
  try {
    const result = await settingService.listMembers({ accountId })
    if (result.data.success) {
      return dispatch({ type: 'INVITE_LIST/REQUEST/SUCCESS', inviteList: result.data.data })
    } else {
      return dispatch({ type: 'INVITE_LIST/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
    return dispatch({ type: 'INVITE_LIST/REQUEST/FAILED', error })
  }
}
