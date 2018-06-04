export const clearAlert = id => async dispatch => {
  dispatch({ type: 'ALERTS/CLEAR', id })
}
