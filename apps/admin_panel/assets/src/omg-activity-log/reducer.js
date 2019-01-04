import createReducer from '../reducer/createReducer'
import _ from 'lodash'
export const activitiesReducer = createReducer(
  {},
  {
    'ACTIVITIES/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ..._.keyBy(data, 'id') }
    }
  }
)
