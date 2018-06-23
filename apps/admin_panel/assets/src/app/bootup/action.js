import createHeaders from '../../utils/headerGenerator'
export const bootstrap = () => async (dispatch, getState, { socket }) => {
  socket.setParams({ headers: createHeaders({ auth: true }) })
  await socket.connect()
  dispatch({ type: 'BOOTSTRAP' })
  return true
}
