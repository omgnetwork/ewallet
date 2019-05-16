import createReducer from '../reducer/createReducer'
import _ from 'lodash'

export const modalReducer = createReducer({
  'MODAL/OPEN': (state, { data }) => ({ ...state, ...data }),
  'MODAL/CLOSE': (state, { data }) => {}
})
