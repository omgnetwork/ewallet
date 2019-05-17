import createHeaders from '../utils/headerGenerator'
export const bootstrap = () => async (dispatch, getState, { socket }) => {
  if (getState().session.authenticated) {
    socket.setParams({ headers: createHeaders({ auth: true }) })
    socket.connect()
  }

  return dispatch({ type: 'BOOTSTRAP' })
}
