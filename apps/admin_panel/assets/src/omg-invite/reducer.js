import createReducer from '../reducer/createReducer'
import _ from 'lodash'
export const inviteListReducer = createReducer(
  {},
  {
    'INVITE_LIST/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ..._.keyBy(data, 'id') }
    }
  }
)

export const inviteListLoadingStatusReducer = createReducer('DEFAULT', {
  'INVITE_LIST/REQUEST/SUCCESS': (state, { data }) => {
    return 'SUCCESS'
  },
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
