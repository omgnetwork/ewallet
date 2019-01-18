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
