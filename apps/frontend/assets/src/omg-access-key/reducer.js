import _ from 'lodash'
import createReducer from '../reducer/createReducer'
export const accessKeysReducer = createReducer(
  {},
  {
    'ACCESS_KEY/CREATE/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'ACCESS_KEY/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'ACCESS_KEYS/REQUEST/SUCCESS': (state, { data }) => {
      return _.merge(state, _.keyBy(data, 'id'))
    },
    'ACCOUNT_KEY_MEMBERSHIPS/REQUEST/SUCCESS': (state, { data }) => {
      return _.merge(state, _.keyBy(data, 'key.id'))
    },
    'ACCESS_KEY/UPDATE/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'CURRENT_ACCOUNT/SWITCH': () => ({})
  }
)

export const accessKeyMembershipsLoadingStatusReducer = createReducer('DEFAULT', {
  'ACCESS_KEY_MEMBERSHIPS/REQUEST/INITIATED': () => 'INITIATED',
  'ACCESS_KEY_MEMBERSHIPS/REQUEST/SUCCESS': () => 'SUCCESS',
  'ACCESS_KEY_MEMBERSHIPS/REQUEST/FAILED': () => 'FAILED'
})

export const accessKeyMembershipsReducer = createReducer({}, {
  'ACCESS_KEY_MEMBERSHIPS/REQUEST/SUCCESS': (state, { data }) => {
    if (data.length) {
      const keyId = data[0].key_id
      return {
        ...state,
        [keyId]: data
      }
    }
    return state
  }
})
