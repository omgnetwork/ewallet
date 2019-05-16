import createReducer from '../reducer/createReducer'
import _ from 'lodash'

const handleModalAction = open => (state, { data }) => {
  const oldModalData = _.get(state[data.id])
  return { ...state, [data.id]: { ...oldModalData, ...data, open } }
}
export const modalReducer = createReducer(
  {},
  {
    'MODAL/OPEN': handleModalAction(true),
    'MODAL/CLOSE': handleModalAction(false)
  }
)
