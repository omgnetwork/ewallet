import createReducer from '../reducer/createReducer'
const initialState = { loadingStatus: false }

const appReducer = createReducer(initialState, {
  'APP/LOADING_STATUS': (state, action) => ({ ...state, ...{ loadingStatus: action.loadingStatus } })
})

export default appReducer
