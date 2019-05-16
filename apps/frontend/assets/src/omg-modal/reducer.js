import createReducer from '../reducer/createReducer'
import _ from 'lodash'

const handleModalAction = open => (state, { data }) => ({
  ...state,
  [data.id]: { ..._.get(state[data.id], {}), open }
})
export const modalReducer = createReducer(
  {},
  {
    'MODAL/OPEN': handleModalAction(true),
    'MODAL/CLOSE': handleModalAction(false)
  }
)
