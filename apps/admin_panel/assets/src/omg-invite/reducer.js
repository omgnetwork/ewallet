import createReducer from '../reducer/createReducer'
export const inviteListReducer = createReducer({}, {
  'INVITE_LIST/REQUEST/SUCCESS': (state, { inviteList }) => {
    return inviteList.data.length > 0 ? _.keyBy(inviteList.data, 'id') : {}
  }
  // 'INVITE/REQUEST/SUCCESS': (state, { invite }) => {
  //   return { ...state, ...{ [invite.id]: invite } }
  // }
})

export const inviteListLoadingStatusReducer = createReducer('DEFAULT', {
  'INVITE_LIST/REQUEST/SUCCESS': (state, { inviteList }) => {
    return 'SUCCESS'
  },
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
