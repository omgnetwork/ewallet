import * as settingService from '../services/settingService'
export const inviteMember = ({ email, redirectUrl, accountId, role }) => async dispatch => {
  dispatch({ type: 'INVITE/REQUEST/INITIATED' })
  try {
    const result = await settingService.inviteMember({
      email,
      redirect_url: redirectUrl,
      account_id: accountId,
      role_name: role
    })
    if (result.data.success) {
      return dispatch({ type: 'INVITE/REQUEST/SUCCESS', invited: result.data.data })
    } else {
      return dispatch({ type: 'INVITE/REQUEST/FAILED', error: result.data.data })
    }
  } catch (error) {
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
