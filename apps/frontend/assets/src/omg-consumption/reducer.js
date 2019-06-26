import _ from 'lodash'
import createReducer from '../reducer/createReducer'
export const consumptionsReducer = createReducer(
  {},
  {
    'CONSUMPTIONS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'TRANSACTION_REQUEST_CONSUMPTION/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'SOCKET_MESSAGE/CONSUMPTION/RECEIVE/SUCCESS': (state, action) => {
      return {
        ...state,
        [action.data.id]: action.data
      }
    },
    'SOCKET_MESSAGE/CONSUMPTION/UPDATE/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.data.id]: action.data } }
    },
    'CONSUMPTION/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.data.id]: action.data } }
    },
    'CONSUMPTION/APPROVE/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.data.id]: action.data } }
    },
    'CONSUMPTION/APPROVE/FAILED': (state, action) => {
      return {
        ...state,
        ...{
          [action.data.id]: {
            ...action.data,
            status: 'falied',
            transaction: {
              ...action.data.transaction,
              error_description: action.error.description
            }
          }
        }
      }
    },
    'CONSUMPTION/CANCEL/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.data.id]: action.data } }
    },
    'CONSUMPTION/REJECT/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.data.id]: action.data } }
    }
  }
)

export const consumptionsLoadingStatusReducer = createReducer('DEFAULT', {
  'CONSUMPTION/REQUEST/INITIATED': () => 'INITIATED',
  'CONSUMPTION/REQUEST/SUCCESS': () => 'SUCCESS',
  'CONSUMPTION/REQUEST/FAILED': () => 'FAILED'
})
