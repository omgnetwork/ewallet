export const visitAccount = accountId => dispatch => {
  return dispatch({ type: 'ACCOUNT/VISIT', accountId })
}
