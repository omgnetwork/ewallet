import createHeaders from '../../utils/headerGenerator'
export const bootstrap = () => async (dispatch, getState, { socket }) => {
  socket.setParams({ headers: createHeaders({ auth: true }) })
  socket.connect()
  return dispatch({ type: 'BOOTSTRAP' })
}
