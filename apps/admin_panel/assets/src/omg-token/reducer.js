import createReducer from '../reducer/createReducer'
export const tokensReducer = createReducer(
  {},
  {
    'TOKENS/REQUEST/SUCCESS': (state, { tokens }) => {
      return { ...state, ..._.keyBy(tokens, 'id') }
    },
    'TOKEN/CREATE/SUCCESS': (state, { token }) => {
      return { ...state, [token.id]: token }
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
