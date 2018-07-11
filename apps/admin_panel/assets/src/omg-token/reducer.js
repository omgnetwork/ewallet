import createReducer from '../reducer/createReducer'
import _ from 'lodash'
export const tokensReducer = createReducer(
  {},
  {
    'TOKENS/REQUEST/SUCCESS': (state, { data }) => {
      return _.merge(state, _.keyBy(data, 'id'))
    },
    'TOKEN/REQUEST/SUCCESS': (state, { data }) => {
      return _.merge(state, {
        [data.token.id]: {
          ...data.token,
          total_supply: data.total_supply
        }
      })
    },
    'TOKEN/CREATE/SUCCESS': (state, { data }) => {
      return { ...state, [data.id]: data }
    },
    'TOKEN/MINT/SUCCESS': (state, { data }) => {
      return {
        ...state,
        [data.token.id]: {
          ...data.token,
          total_supply: state[data.token.id].total_supply + data.amount
        }
      }
    },
    'CURRENT_ACCOUNT/SWITCH': () => {
      return {}
    }
  }
)

export const mintedTokenHistoryReducer = createReducer(
  {},
  {
    'TOKEN_HISTORY/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ..._.keyBy(data, 'id') }
    },
    'CURRENT_ACCOUNT/SWITCH': () => {
      return {}
    }
  }
)

export const tokensLoadingStatusReducer = createReducer('DEFAULT', {
  'TOKENS/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'TOKENS/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'TOKENS/REQUEST/FAILED': (state, action) => 'FAILED',
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
