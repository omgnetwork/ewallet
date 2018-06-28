import createReducer from '../reducer/createReducer'
export const inviteListReducer = createReducer({}, {
  'INVITE_LIST/REQUEST/SUCCESS': (state, { inviteList }) => {
    return inviteList.data.length > 0 ? _.keyBy(inviteList.data, 'id') : {}
  }
})

export const inviteListLoadingStatusReducer = createReducer('DEFAULT', {
  'INVITE_LIST/REQUEST/SUCCESS': (state, { inviteList }) => {
    return 'SUCCESS'
  },
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
