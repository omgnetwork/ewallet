import createReducer from '../reducer/createReducer'

export const exchangePairsReducer = createReducer(
  {},
  {
    'EXCHANGE_PAIRS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'EXCHANGE_PAIR/UPDATE/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data.data, 'id') }
    },
    'EXCHANGE_PAIR/DELETE/SUCCESS': (state, action) => {
      return _.omit(state, action.data.data[0].id)
    },
    'EXCHANGE_PAIR/CREATE/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data.data, 'id') }
    }
  }
)
