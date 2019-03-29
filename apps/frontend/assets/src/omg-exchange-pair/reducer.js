import createReducer from '../reducer/createReducer'

export const exchangePairsReducer = createReducer(
  {},
  {
    'EXCHANGE_PAIRS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'EXCHANGE_PAIR/CREATE/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data.data, 'id') }
    }
  }
)
