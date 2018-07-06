import createReducer from '../reducer/createReducer'
import uuid from 'uuid/v4'
import React from 'react'
const createAlertState = (text, type) => {
  return { id: uuid(), text, type }
}
export const alertsReducer = createReducer([], {
  'ALERTS/CLEAR': (state, { id }) => {
    return state.filter(alert => alert.id !== id)
  },
  COPY_TO_CLIPBAORD: (state, { data }) => {
    return [
      ...state,
      createAlertState(
        <div>
          Copied <b>{data}</b> to clipboard.
        </div>
      , 'success')

    ]
  },
  'API_KEY/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Api key was successfully created.', 'success')]
  },
  'ACCESS_KEY/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Access key was successfully created.', 'success')]
  },
  'EXCHANGE_PAIR/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Exchange pair was successfully created.', 'success')]
  },
  'ACCOUNT/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Account was successfully created.', 'success')]
  },
  'TOKEN/CREATE/SUCCESS': state => {
    return [...state, createAlertState('token was successfully created.', 'success')]
  },
  'TOKEN/MINT/SUCCESS': state => {
    return [...state, createAlertState('Minted token successfully.', 'success')]
  },
  'CURRENT_ACCOUNT/UPDATE/SUCCESS': state => {
    return [...state, createAlertState('Updated account successfully.', 'success')]
  },
  'INVITE/REQUEST/SUCCESS': state => {
    return [...state, createAlertState('Invited member successfully.', 'success')]
  },
  'CATEGORY/CREATE/SUCCESS': (state, { category }) => {
    return [...state, createAlertState(`Created category successfully.`, 'success')]
  },
  'CURRENT_USER/UPDATE/SUCCESS': (state, { user }) => {
    return [...state, createAlertState(`Updated user setting successfully.`, 'success')]
  },
  'TRANSACTION/CREATE/SUCCESS': (state, { transaction }) => {
    return [...state, createAlertState(`Transffered successfully.`, 'success')]
  },
  'CONSUMPTION/APPROVE/SUCCESS': (state, { data }) => {
    return [...state, createAlertState(`Approved consumption ${data.id} successfully.`, 'success')]
  },
  'CONSUMPTION/APPROVE/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'TRANSACTION_REQUEST/CREATE/SUCCESS': state => {
    return [...state, createAlertState(`Transaction request was successfully created.`, 'success')]
  },
  'TRANSACTION_REQUEST/CONSUME/SUCCESS': state => {
    return [...state, createAlertState(`Consumed transaction request.`, 'success')]
  }
})
