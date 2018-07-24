import createReducer from '../reducer/createReducer'
import _ from 'lodash'
export const usersReducer = createReducer(
  {},
  {
    'USERS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'USER/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'USER/CREATE/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
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
