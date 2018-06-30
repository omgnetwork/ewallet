import createReducer from '../reducer/createReducer'
import uuid from 'uuid/v4'
const createAlertState = (text, type) => {
  return { id: uuid(), text, type }
}
export const alertsReducer = createReducer([], {
  'ALERTS/CLEAR': (state, { id }) => {
    return state.filter(alert => alert.id !== id)
  },
  'COPY_TO_CLIPBAORD': (state, { data }) => {
    return [...state, createAlertState(`Copied ${data} to clipboard.`)]
  },
  'API_KEY/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Api key has successfully created.')]
  },
  'ACCESS_KEY/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Access key has successfully created.')]
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
  },
  'CATEGORY/CREATE/SUCCESS': (state, { category }) => {
    return [...state, createAlertState(`Created category successfully.`)]
  },
  'CURRENT_USER/UPDATE/SUCCESS': (state, { user }) => {
    return [...state, createAlertState(`Update user setting successfully.`)]
  },
  'TRANSACTION/CREATE/SUCCESS': (state, { transaction }) => {
    return [...state, createAlertState(`Transfer successfully.`)]
  },
  'TRANSACTION_REQUEST/CREATE/SUCCESS': state => {
    return [...state, createAlertState(`Transaction request has successfully created.`)]
  }
})
