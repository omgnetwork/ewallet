import { applyMiddleware, createStore } from 'redux'
import reducer from '../reducer'
import thunk from 'redux-thunk'
import { composeWithDevTools } from 'redux-devtools-extension'

export function configureStore (initialState = {}, injectedThunk = {}) {
  return createStore(
    reducer,
    initialState,
    composeWithDevTools(applyMiddleware(thunk.withExtraArgument(injectedThunk)))
  )
}
