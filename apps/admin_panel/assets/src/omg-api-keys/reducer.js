import createReducer from '../reducer/createReducer'
export const apiKeysReducer = createReducer(
  {},
  {
    'API_KEYS/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ..._.keyBy(data, 'id') }
    },
    'API_KEY/CREATE/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'API_KEY/UPDATE/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'CURRENT_ACCOUNT/SWITCH': () => []
  }
)

export const apiKeysLoadingStatusReducer = createReducer('DEFAULT', {
  'API_KEYS/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
