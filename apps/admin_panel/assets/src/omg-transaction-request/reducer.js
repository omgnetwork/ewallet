import createReducer from '../reducer/createReducer'
import _ from 'lodash'
export const transactionRequestsReducer = createReducer(
  {},
  {
    'TRANSACTION_REQUESTS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'TRANSACTION_REQUEST/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.data.id]: action.data } }
    },
    'TRANSACTION_REQUEST/CONSUME/SUCCESS': (state, action) => {
      return {
        ...state,
        ...{
          [action.data.transaction_request.id]: action.data.transaction_request
        }
      }
    },
    'TRANSACTION_REQUEST/APPROVE/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.data.id]: action.data } }
    },
    'CONSUMPTION/CONSUME/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.data.id]: action.data } }
    }
  }
)

export const transactionRequestsLoadingStatusReducer = createReducer('DEFAULT', {
  'CONSUMPTION/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'CONSUMPTION/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CONSUMPTION/REQUEST/FAILED': (state, action) => 'FAILED'
})
