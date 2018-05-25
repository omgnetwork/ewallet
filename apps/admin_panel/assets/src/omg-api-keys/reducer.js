import createReducer from '../reducer/createReducer'
export const apiKeysReducer = createReducer([], {
  'API_KEY/CREATE/SUCCESS': (state, { apiKey }) => {
    return [...state, apiKey]
  },
  'API_KEY/REQUEST/SUCCESS': (state, { apiKeys }) => {
    return [...state, ...apiKeys]
  },
  'CURRENT_ACCOUNT/SWITCH': () => []
})

export const apiKeysLoadingStatusReducer = createReducer('DEFAULT', {
  'API_KEY/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
