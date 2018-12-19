import createReducer from '../reducer/createReducer'
import _ from 'lodash'

export const configurationReducer = createReducer(
  {},
  {
    'CONFIGURATIONS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data.data, 'key') }
    },
    'CONFIGURATIONS/UPDATE/SUCCESS': (state, action) => {
      return { ...state, ..._.filter(action.data.data, ({ object }) => object !== 'error') }
    }
  }
)
