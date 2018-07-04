import createReducer from '../reducer/createReducer'
export const tokensReducer = createReducer(
  {},
  {
    'TOKENS/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ..._.keyBy(data, 'id') }
    },
    'TOKEN/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, [data.id]: data }
    },
    'TOKEN/CREATE/SUCCESS': (state, { data }) => {
      return { ...state, [data.id]: data }
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
