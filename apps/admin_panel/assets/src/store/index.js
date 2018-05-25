import { applyMiddleware, createStore } from 'redux'
import reducer from '../reducer'
import thunk from 'redux-thunk'
import { composeWithDevTools } from 'redux-devtools-extension'

function configureStore (initialState = {}) {
  return createStore(reducer, initialState, composeWithDevTools(applyMiddleware(thunk)))
}

const store = configureStore()

if (module.hot) {
  module.hot.accept('../reducer', () => {
    store.replaceReducer(require('../reducer').default)
  })
}

export default store
