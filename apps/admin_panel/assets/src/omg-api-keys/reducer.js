import createReducer from '../reducer/createReducer'
export const apiKeysReducer = createReducer(
  {},
  {
    'API_KEY/CREATE/SUCCESS': (state, { apiKey }) => {
      return { ...state, ...{ [apiKey.id]: apiKey } }
    },
    'API_KEY/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ..._.keyBy(data, 'id') }
    },
    'API_KEY/UPDATE/SUCCESS': (state, { apiKey }) => {
      return { ...state, ...{ [apiKey.id]: apiKey } }
    },
    'CURRENT_ACCOUNT/SWITCH': () => []
  }
)

export const apiKeysLoadingStatusReducer = createReducer('DEFAULT', {
  'API)KEYS/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
