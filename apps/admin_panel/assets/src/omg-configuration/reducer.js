import createReducer from '../reducer/createReducer'
import _ from 'lodash'

export const configurationReducer = createReducer(
  {},
  {
    'CONFIGURATIONS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'CONFIGURATIONS/UPDATE/SUCCESS': (state, action) => {
      return { ...state, [action.data.id]: action.data }
    }
  }
)
