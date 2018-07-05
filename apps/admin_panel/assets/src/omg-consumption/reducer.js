import createReducer from '../reducer/createReducer'

export const consumptionsReducer = createReducer(
  {},
  {
    'CONSUMPTIONS/REQUEST/SUCCESS': (state, action) => {
      return { ...state, ..._.keyBy(action.data, 'id') }
    },
    'TRANSACTION_REQUEST_CONSUMPTION/REQUEST/SUCCESS': (state, action) => {
      return _.merge(state, _.keyBy(action.data, 'id'))
    },
    'SOCKET_MESSAGE/CONSUMPTION/REQUEST/SUCCESS': (state, action) => {
      return {
        ...state,
        ...{
          [action.data.id]: {
            ...action.data,
            new: true
          }
        }
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
      return action.data
        ? { ...state, ...{ [action.data.id]: { ...action.data, status: 'failed' } } }
        : state
    },
    'CONSUMPTION/REJECT/SUCCESS': (state, action) => {
      return { ...state, ...{ [action.data.id]: action.data } }
    },
    'CONSUMPTION/REJECT/FAILED': (state, action) => {
      return { ...state, ...{ [action.data.id]: action.data } }
    }
  }
)

export const consumptionsLoadingStatusReducer = createReducer('DEFAULT', {
  'CONSUMPTION/REQUEST/INITIATED': (state, action) => 'INITIATED',
  'CONSUMPTION/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CONSUMPTION/REQUEST/FAILED': (state, action) => 'FAILED'
})
