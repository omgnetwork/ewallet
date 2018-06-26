import createReducer from '../reducer/createReducer'

export const usersReducer = createReducer(
  {},
  {
    'USERS/REQUEST/SUCCESS': (state, action) => {
      return _.keyBy(action.data, 'id')
    },
    'USER/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.user.id]: action.user } }
    },
    'USER/CREATE/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.user.id]: action.user } }
    },
    'CURRENT_ACCOUNT/SWITCH': () => ({})
  }
)

export const usersLoadingStatusReducer = createReducer('DEFAULT', {
  'USERS/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'USERS/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'USERS/REQUEST/FAILED': (state, action) => 'FAILED',
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
