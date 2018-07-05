import createReducer from '../reducer/createReducer'
import uuid from 'uuid/v4'
import React from 'react'
import { Link } from 'react-router-dom'
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
        </div>,
        'success'
      )
    ]
  },
  'API_KEY/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Api key has successfully created.', 'success')]
  },
  'ACCESS_KEY/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Access key has successfully created.', 'success')]
  },
  'EXCHANGE_PAIR/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Exchange pair has successfully created.', 'success')]
  },
  'ACCOUNT/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Account has successfully created.', 'success')]
  },
  'TOKEN/CREATE/SUCCESS': state => {
    return [...state, createAlertState('token has successfully created.', 'success')]
  },
  'TOKEN/MINT/SUCCESS': state => {
    return [...state, createAlertState('Minted token successfully.', 'success')]
  },
  'CURRENT_ACCOUNT/UPDATE/SUCCESS': state => {
    return [...state, createAlertState('Update account successfully.', 'success')]
  },
  'INVITE/REQUEST/SUCCESS': state => {
    return [...state, createAlertState('Invite member successfully.', 'success')]
  },
  'CATEGORY/CREATE/SUCCESS': (state, { category }) => {
    return [...state, createAlertState(`Created category successfully.`, 'success')]
  },
  'CURRENT_USER/UPDATE/SUCCESS': (state, { user }) => {
    return [...state, createAlertState(`Update user setting successfully.`, 'success')]
  },
  'TRANSACTION/CREATE/SUCCESS': (state, { transaction }) => {
    return [...state, createAlertState(`Transfer successfully.`, 'success')]
  },
  'CONSUMPTION/APPROVE/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'CONSUMPTION/REJECT/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'CONSUMPTION/REJECT/SUCCESS': (state, { data }) => {
    return [
      ...state,
      createAlertState(
        <div>
          Rejected consumption{' '}
          <Link to={{ search: `?show-consumption-tab=${data.id}` }}>{data.id}</Link> successfully.
        </div>,
        'success'
      )
    ]
  },
  'TRANSACTION_REQUEST/CREATE/SUCCESS': state => {
    return [...state, createAlertState(`Transaction request has successfully created.`, 'success')]
  },
  'TRANSACTION_REQUEST/CONSUME/SUCCESS': (state, { data }) => {
    if (data.status === 'confirmed') {
      return [...state, createAlertState(`Consumed transaction request.`, 'success')]
    }
    return state
  },
  'SOCKET_MESSAGE/CONSUMPTION/UPDATE/SUCCESS': (state, { data }) => {
    if (data.status === 'confirmed' && data.transaction_request.require_confirmation) {
      return [
        ...state,
        createAlertState(
          <div>
            Approved consumption{' '}
            <Link to={{ search: `?show-consumption-tab=${data.id}` }}>{data.id}</Link> successfully.
          </div>,
          'success'
        )
      ]
    }
    return state
  },
  'SOCKET_MESSAGE/CONSUMPTION/RECEIVE/SUCCESS': (state, { data }) => {
    if (data.status === 'pending') {
      return [
        ...state,
        createAlertState(
          <div>
            New pending consumption{' '}
            <Link to={{ search: `?show-consumption-tab=${data.id}` }}>{data.id}</Link>
          </div>,
          'success'
        )
      ]
    }
    if (data.status === 'confirmed') {
      return [...state, createAlertState(`Consumed transaction request.`, 'success')]
    }
    return state
  }
})
