import createReducer from '../reducer/createReducer'
export const currentUserReducer = createReducer({}, {
  'LOGIN/SUCCESS': (state, { currentUser }) => {
    return currentUser
  },
  'CURRENT_USER/REQUEST/SUCCESS': (state, { currentUser }) => {
    return currentUser
  },
  'CURRENT_USER/UPDATE/SUCCESS': (state, { currentUser }) => {
    return currentUser
  }
})

export const currentUserLoadingStatusReducer = createReducer('DEFAULT', {
  'CURRENT_USER/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'CURRENT_USER/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CURRENT_USER/REQUEST/FAILED': (state, action) => 'FAILED'
})
