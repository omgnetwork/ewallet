import createReducer from '../reducer/createReducer'

export const transactionsReducer = createReducer(
  {},
  {
    'TRANSACTIONS/REQUEST/SUCCESS': (state, action) => {
      return {...state, ..._.keyBy(action.transactions, 'id')}
    }
  }
)

export const transactionsLoadingStatusReducer = createReducer('DEFAULT', {
  'TRANSACTIONS/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'TRANSACTIONS/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'TRANSACTIONS/REQUEST/FAILED': (state, action) => 'FAILED',
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
