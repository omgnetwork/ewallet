import createReducer from '../reducer/createReducer'
import _ from 'lodash'

export function handleAccountReceived (state, { data }) {
  return { ...state, ...{ [data.id]: data } }
}

export const accountsReducer = createReducer(
  {},
  {
    'ACCOUNTS/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ..._.keyBy(data, 'id') }
    },
    'ACCOUNT/CREATE/SUCCESS': handleAccountReceived,
    'ACCOUNT/UPDATE/SUCCESS': handleAccountReceived,
    'ACCOUNT/REQUEST/SUCCESS': handleAccountReceived
  }
)

export const accountsLoadingStatusReducer = createReducer('DEFAULT', {
  'ACCOUNTS/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'ACCOUNTS/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'ACCOUNTS/REQUEST/FAILED': (state, action) => 'FAILED'
})
