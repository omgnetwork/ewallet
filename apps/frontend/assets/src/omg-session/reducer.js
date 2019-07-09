import createReducer from '../reducer/createReducer'

export const sessionReducer = createReducer(
  {},
  {
    'SESSION/LOGIN/SUCCESS': () => {
      return { authenticated: true }
    },
    'SESSION/LOGOUT/SUCCESS': () => {
      return { authenticated: false }
    }
  }
)
