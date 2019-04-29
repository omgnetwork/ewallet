import createReducer from '../reducer/createReducer'
import uuid from 'uuid/v4'
import React from 'react'
import { Link } from 'react-router-dom'
import styled from 'styled-components'
const CopyTextContainer = styled.div`
  b {
    display: inline-block;
    max-width: 280px;
    text-overflow: ellipsis;
    overflow: hidden;
    white-space: nowrap;
    vertical-align: bottom;
  }
`
const createAlertState = (text, type) => {
  return { id: uuid(), text, type }
}

const errorStateHandler = (state, { error }) => {
  return [...state, createAlertState(`${error.description || error}`, 'error')]
}

export const alertsReducer = createReducer([], {
  'ALERTS/CLEAR': (state, { id }) => {
    return state.filter(alert => alert.id !== id)
  },
  'CLIPBOARD/COPY/SUCCESS': (state, { data }) => {
    return [
      ...state,
      createAlertState(
        <CopyTextContainer>
          <span>Copied</span> <b>{data.slice(0, 100)}</b> <span>to clipboard.</span>
        </CopyTextContainer>,
        'success'
      )
    ]
  },
  'API_KEY/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Client key was successfully created.', 'success')]
  },
  'ACCESS_KEY/CREATE/SUCCESS': state => {
    return [...state, createAlertState('New admin key successfully created.', 'success')]
  },
  'EXCHANGE_PAIR/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Exchange pair was successfully created.', 'success')]
  },
  'ACCOUNT/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Account was successfully created.', 'success')]
  },
  'TOKEN/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Token was successfully created.', 'success')]
  },
  'TOKEN/MINT/SUCCESS': state => {
    return [...state, createAlertState('Minted token successfully.', 'success')]
  },
  'ACCOUNT/UPDATE/SUCCESS': state => {
    return [...state, createAlertState('Updated account successfully.', 'success')]
  },
  'INVITE/REQUEST/SUCCESS': state => {
    return [...state, createAlertState('Invited member successfully.', 'success')]
  },
  'CATEGORY/CREATE/SUCCESS': (state, { category }) => {
    return [...state, createAlertState('Created category successfully.', 'success')]
  },
  'ACCOUNT/ASSIGN_KEY/SUCCESS': state => {
    return [...state, createAlertState('Assign key to account successfully.', 'success')]
  },
  'CURRENT_USER/UPDATE/SUCCESS': (state, { user }) => {
    return [...state, createAlertState('Updated user settings successfully.', 'success')]
  },
  'PASSWORD/UPDATE/SUCCESS': (state, { user }) => {
    return [...state, createAlertState('Updated password successfully.', 'success')]
  },
  'TRANSACTION/CREATE/SUCCESS': (state, { transaction }) => {
    return [...state, createAlertState('Transferred successfully.', 'success')]
  },
  'TRANSACTION_REQUEST/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Transaction request was successfully created.', 'success')]
  },
  'TRANSACTION_REQUEST/CONSUME/SUCCESS': (state, { data }) => {
    if (data.status === 'confirmed') {
      return [...state, createAlertState('Consumed transaction request.', 'success')]
    }
    return state
  },
  'SOCKET_MESSAGE/CONSUMPTION/UPDATE/SUCCESS': (state, { data }) => {
    if (data.status === 'confirmed' && data.transaction_request.require_confirmation) {
      return [
        ...state,
        createAlertState(
          <div>
            Consumption <Link to={{ search: `?show-consumption-tab=${data.id}` }}>{data.id}</Link>{' '}
            was approved successfully.
          </div>,
          'success'
        )
      ]
    }
    if (data.status === 'rejected') {
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
    return state
  },
  'CONFIGURATIONS/UPDATE/SUCCESS': (state, { data }) => {
    return [
      ...state,
      createAlertState('Updated configuration successfully, reloading application...', 'success')
    ]
  },
  'TRANSACTIONS/EXPORT/SUCCESS': (state, { error }) => {
    return [...state, createAlertState(<div>Exported transactions successfully</div>, 'success')]
  },
  'CONFIGURATIONS/UPDATE/FAILED': errorStateHandler,
  'TRANSACTIONS/EXPORT/FAILED': errorStateHandler,
  'PASSWORD/UPDATE/FAILED': errorStateHandler,
  'CURRENT_USER/UPDATE/FAILED': errorStateHandler,
  'CONSUMPTION/APPROVE/FAILED': errorStateHandler,
  'CONSUMPTION/REJECT/FAILED': errorStateHandler,
  'ACCOUNT/CREATE/FAILED': errorStateHandler,
  'ACCOUNT/ASSIGN_KEY/FAILED': errorStateHandler,
  'CATEGORY/CREATE/FAILED': errorStateHandler,
  'API_KEY/UPDATE/FAILED': errorStateHandler,
  'API_KEY/CREATE/FAILED': errorStateHandler,
  'ACCESS_KEY/CREATE/FAILED': errorStateHandler,
  'CONFIGURATIONS/REQUEST/FAILED': errorStateHandler,
  'INVITE/REQUEST/FAILED': errorStateHandler
})
