import createReducer from '../reducer/createReducer'
import uuid from 'uuid/v4'
const createAlertState = text => {
  return { id: uuid(), text }
}
export const alertsReducer = createReducer([], {
  'ALERTS/CLEAR': (state, { id }) => {
    return state.filter(alert => alert.id !== id)
  },
  'API_KEY/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Api key has successfully created.')]
  },
  'ACCOUNT/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Account has successfully created.')]
  },
  'TOKEN/CREATE/SUCCESS': state => {
    return [...state, createAlertState('token has successfully created.')]
  },
  'TOKEN/MINT/SUCCESS': state => {
    return [...state, createAlertState('Minted token successfully.')]
  },
  'CURRENT_ACCOUNT/UPDATE/SUCCESS': state => {
    return [...state, createAlertState('Update account successfully.')]
  },
  'INVITE/REQUEST/SUCCESS': state => {
    return [...state, createAlertState('Invite member successfully.')]
  }
})
