export const handleWebsocketMessage = store => message => {
  switch (message.event) {
    case 'transaction_consumption_request':
      return store.dispatch({
        type: 'SOCKET_MESSAGE/CONSUMPTION/RECEIVE/SUCCESS',
        data: message.data
      })
    case 'transaction_consumption_finalized':
      return store.dispatch({
        type: 'SOCKET_MESSAGE/CONSUMPTION/UPDATE/SUCCESS',
        data: message.data
      })
    default:
      break
  }
}
