import createReducer from '../reducer/createReducer'
export const inviteListReducer = createReducer({}, {
  'INVITE_LIST/REQUEST/SUCCESS': (state, { data }) => {
    return data.length > 0 ? _.keyBy(data, 'id') : {}
  }
})

export const inviteListLoadingStatusReducer = createReducer('DEFAULT', {
  'INVITE_LIST/REQUEST/SUCCESS': (state, { data }) => {
    return 'SUCCESS'
  },
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
