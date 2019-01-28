import createReducer from '../reducer/createReducer'
import _ from 'lodash'
export const adminsReducer = createReducer(
  {},
  {
    'ADMINS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'ADMIN/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    }
  }
)
