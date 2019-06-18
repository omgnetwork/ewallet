import _ from 'lodash'
import createReducer from '../reducer/createReducer'
export const transactionsReducer = createReducer(
  {},
  {
    'TRANSACTIONS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'TRANSACTION/REQUEST/SUCCESS': (state, action) => {
      return { ...state, [action.data.id]: action.data }
    },
    'TRANSACTION/CREATE/SUCCESS': (state, action) => {
      return { ...state, [action.data.id]: { ...action.data, __new: true } }
    },
    'CURRENT_ACCOUNT/SWITCH': () => {
      return {}
    }
  }
)
