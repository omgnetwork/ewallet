import { setRecentAccount } from '../services/sessionService'
export const visitAccount = accountId => (dispatch, getState) => {
  const currentUser = getState().currentUser
  dispatch({ type: 'ACCOUNT/VISIT', accountId })
  setRecentAccount({ [currentUser.id]: getState().recentAccounts })
}
