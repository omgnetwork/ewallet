import _ from 'lodash'
import createReducer from '../reducer/createReducer'
export const exportsReducer = createReducer(
  {},
  {
    'EXPORTS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'EXPORT/CREATE/SUCCESS': (state, action) => {
      return { ...state, [action.data.id]: action.data }
    },
    'EXPORT/REQUEST/SUCCESS': (state, action) => {
      return { ...state, [action.data.id]: action.data }
    },
    'CURRENT_ACCOUNT/SWITCH': () => {
      return {}
    }
  }
)
