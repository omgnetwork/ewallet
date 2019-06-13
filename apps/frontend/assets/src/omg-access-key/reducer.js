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

export const accessKeyMembershipsLoadingStatusReducer = createReducer(
  'DEFAULT',
  {
    'ACCESS_KEY_MEMBERSHIPS/REQUEST/INITIATED': () => 'INITIATED',
    'ACCESS_KEY_MEMBERSHIPS/REQUEST/SUCCESS': () => 'SUCCESS',
    'ACCESS_KEY_MEMBERSHIPS/REQUEST/FAILED': () => 'FAILED'
  }
)

export const accessKeyMembershipsReducer = createReducer(
  {},
  {
    'ACCESS_KEY_MEMBERSHIPS/REQUEST/SUCCESS': (state, { data }) => {
      if (data.length) {
        const keyId = data[0].key_id
        return {
          ...state,
          [keyId]: data
        }
      }
      return state
    },
    'ACCOUNT/UNASSIGN_KEY/SUCCESS': (
      state,
      { params: { keyId, accountId } }
    ) => {
      const _state = Object.assign({}, state)
      const membership = _state[keyId]
      return {
        ...state,
        [keyId]: membership.filter(i => i.account_id !== accountId)
      }
    },
    'ACCOUNT/ASSIGN_KEY/SUCCESS': (
      state,
      { params: { keyId, role, accountId } }
    ) => {
      const _state = Object.assign({}, state)
      const membership = _state[keyId]

      if (membership) {
        const membershipAccount = {
          ...membership.find(i => i.account_id === accountId),
          role
        }

        const index = _.findIndex(membership, i => {
          return i.account_id === accountId
        })

        const newMembership = [...membership]
        newMembership.splice(index, 1, membershipAccount)
        return {
          ...state,
          [keyId]: newMembership
        }
      }
      return {}
    }
  }
)
