import _ from 'lodash'
import createReducer from '../reducer/createReducer'
export const activitiesReducer = createReducer(
  {},
  {
    'ACTIVITIES/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ..._.keyBy(data, 'id') }
    }
  }
)
