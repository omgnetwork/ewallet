import createReducer from '../reducer/createReducer'
export const accessKeyReducer = createReducer(
  {},
  {
    'ACCESS_KEY/CREATE/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'ACCESS_KEY/REQUEST/SUCCESS': (state, { data }) => {
      return { ...state, ..._.keyBy(data, 'id') }
    },
    'ACCESS_KEY/UPDATE/SUCCESS': (state, { data }) => {
      return { ...state, ...{ [data.id]: data } }
    },
    'CURRENT_ACCOUNT/SWITCH': () => []
  }
)

export const accessKeyLoadingStatusReducer = createReducer('DEFAULT', {
  'ACCESS_KEY/REQUEST/SUCCESS': (state, action) => 'SUCCESS',
  'CURRENT_ACCOUNT/SWITCH': () => 'DEFAULT'
})
