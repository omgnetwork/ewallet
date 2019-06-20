import _ from 'lodash'
import createReducer from '../reducer/createReducer'
export const inviteListReducer = createReducer(
  {},
  {
    'INVITE_LIST/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ..._.keyBy(data, 'user_id') }
    }
  }
)

export const inviteListLoadingStatusReducer = createReducer('DEFAULT', {
  'INVITE_LIST/REQUEST/SUCCESS': (state, { data }) => {
    return 'SUCCESS'
  }
})
