import createReducer from '../reducer/createReducer'
import _ from 'lodash'

export const configurationReducer = createReducer(
  {},
  {
    'CONFIGURATIONS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data.data, 'key') }
    },
    'CONFIGURATIONS/UPDATE/SUCCESS': (state, action) => {
      console.log(action.data.data, '######')
      return { ...state, ...action.data.data }
    }
  }
)
