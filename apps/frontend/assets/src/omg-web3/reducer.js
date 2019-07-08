import _ from 'lodash'
import createReducer from '../reducer/createReducer'
export const metamaskReducer = createReducer(
  {},
  {
    'METAMASK/ENABLE/SUCCESS': state => {
      return { ...state, enable: true }
    },
    'METAMASK/SET_EXIST': (state, { data: exist }) => {
      return { ...state, exist: exist }
    }
  }
)
