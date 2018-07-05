import { applyMiddleware, createStore } from 'redux'
import reducer from '../reducer'
import thunk from 'redux-thunk'
import { composeWithDevTools } from 'redux-devtools-extension'
import SocketConnector from '../../src/socket/connector'
import { WEBSOCKET_URL } from '../config'
import { handleWebsocketMessage } from '../socket/handleMessage'
// import { loadingBarMiddleware } from 'react-redux-loading-bar'
export function configureStore (initialState = {}, injectedThunk = {}) {
  return createStore(
    reducer,
    initialState,
    composeWithDevTools(
      applyMiddleware(
        thunk.withExtraArgument(injectedThunk),
        // loadingBarMiddleware({
        //   promiseTypeSuffixes: ['INITIATED', 'SUCCESS', 'FAILED']
        // })
      )
    )
  )
}
const socket = new SocketConnector(WEBSOCKET_URL)
export const store = configureStore({}, { socket })
socket.on('message', handleWebsocketMessage(store))
