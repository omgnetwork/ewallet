import createReducer from '../reducer/createReducer'

export const cacheReducer = createReducer(
  {},
  {
    'ACCOUNTS/REQUEST/SUCCESS': (state, action) => {
      return { ...state,
        [action.cacheKey]:
        { ids: action.data.map(d => d.id), pagination: action.pagination }
      }
    },
    'CURRENT_ACCOUNT/SWITCH': () => ({})
  }
)
