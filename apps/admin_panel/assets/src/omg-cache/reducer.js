import createReducer from '../reducer/createReducer'

export const cacheReducer = createReducer(
  {},
  {
    'ACCOUNTS/REQUEST/SUCCESS': (state, action) => {
      return {
        ...state,
        [action.cacheKey]: { ids: action.data.map(d => d.id), pagination: action.pagination }
      }
    },
    'TOKENS/REQUEST/SUCCESS': (state, action) => {
      return {
        ...state,
        [action.cacheKey]: { ids: action.data.map(d => d.id), pagination: action.pagination }
      }
    },
    'API_KEY/REQUEST/SUCCESS': (state, action) => {
      return {
        ...state,
        [action.cacheKey]: { ids: action.data.map(d => d.id), pagination: action.pagination }
      }
    },
    'WALLETS/REQUEST/SUCCESS': (state, action) => {
      return {
        ...state,
        [action.cacheKey]: { ids: action.data.map(d => d.address), pagination: action.pagination }
      }
    },
    'TRANSACTIONS/REQUEST/SUCCESS': (state, action) => {
      return {
        ...state,
        [action.cacheKey]: { ids: action.data.map(d => d.id), pagination: action.pagination }
      }
    },
    'USERS/REQUEST/SUCCESS': (state, action) => {
      return {
        ...state,
        [action.cacheKey]: { ids: action.data.map(d => d.id), pagination: action.pagination }
      }
    },
    'CURRENT_ACCOUNT/SWITCH': () => ({})
  }
)
