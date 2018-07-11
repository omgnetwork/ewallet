import createReducer from '../reducer/createReducer'
import _ from 'lodash'
export const transactionsReducer = createReducer(
  {},
  {
    'TRANSACTIONS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'TRANSACTION/CREATE/SUCCESS': (state, action) => {
      return { ...state, [action.data.id]: action.data }
    },
    'TRANSACTION/REQUEST/SUCCESS': (state, action) => {
      return { ...state, [action.data.id]: action.data }
    },
    'CURRENT_ACCOUNT/SWITCH': () => {
      return {}
    }
  }
)

export const transactionsLoadingStatusReducer = createReducer('DEFAULT', {
  'TRANSACTIONS/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'TRANSACTIONS/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'TRANSACTIONS/REQUEST/FAILED': (state, action) => 'FAILED',
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
