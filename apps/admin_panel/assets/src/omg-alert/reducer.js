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
    return [...state, createAlertState('Api key was successfully created.', 'success')]
  },
  'ACCESS_KEY/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Access key was successfully created.', 'success')]
  },
  'EXCHANGE_PAIR/CREATE/SUCCESS': state => {
    return [...state, createAlertState('Exchange pair has successfully created.', 'success')]
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
  'PASSWORD/UPDATE/SUCCESS': (state, { user }) => {
    return [...state, createAlertState(`Updated password successfully.`, 'success')]
  },
  'TRANSACTION/CREATE/SUCCESS': (state, { transaction }) => {
    return [...state, createAlertState(`Transferred successfully.`, 'success')]
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
  'PASSWORD/UPDATE/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'CONSUMPTION/APPROVE/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'CONSUMPTION/REJECT/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'ACCOUNT/CREATE/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'CATEGORY/CREATE/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'API_KEY/UPDATE/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'API_KEY/CREATE/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'ACCESS_KEY/CREATE/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'CURRENT_ACCOUNT/UPDATE/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
  },
  'INVITE/REQUEST/FAILED': (state, { error }) => {
    return [...state, createAlertState(`${error.description || error}`, 'error')]
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
  }
})
