import React from 'react'
import moment from 'moment'
import { Link, withRouter } from 'react-router-dom'
import styled from 'styled-components'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import { compose } from 'recompose'
import { connect } from 'react-redux'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import { Button } from '../omg-uikit'
import * as consumptionAction from '../omg-consumption/action'

const InformationItem = styled.div`
  color: ${props => props.theme.colors.B200};
  b {
    vertical-align: bottom;
  }
  span {
    vertical-align: bottom;
  }
  :not(:last-child) {
    margin-bottom: 10px;
  }
`
const ActionContainer = styled.div`
  padding: 20px;
  border-radius: 4px;
  margin-bottom: 20px;
  border: 1px solid ${props => props.theme.colors.S400};
  button {
    margin-right: 20px;
    width: 100px;
    margin-top: 10px;
  }
`
const enhance = compose(
  withRouter,
  connect(
    null,
    {
      approveConsumptionById: consumptionAction.approveConsumptionById,
      rejectConsumptionById: consumptionAction.rejectConsumptionById,
      cancelConsumptionById: consumptionAction.cancelConsumptionById
    }
  )
)

function ConsumptionBox ({
  consumption,
  location,
  cancelConsumptionById,
  rejectConsumptionById,
  approveConsumptionById
}) {
  const searchObject = queryString.parse(location.search)
  const tq = _.get(consumption, 'transaction_request', {})
  return (
    <ActionContainer>
      <InformationItem>
        <b>Request:</b>{' '}
        <span>
          <Link
            to={{
              search: queryString.stringify({
                page: searchObject.page,
                'show-request-tab': tq.id
              })
            }}
          >
            {tq.id}
          </Link>
        </span>
      </InformationItem>
      <InformationItem>
        <b>Type:</b> <span>{tq.type}</span>
      </InformationItem>
      <InformationItem>
        <b>Requester Address:</b>{' '}
        <Link
          to={{
            pathname: `/accounts/${tq.account_id}/wallets/${tq.address}`,
            search: location.search
          }}
        >
          {tq.address}
        </Link>
      </InformationItem>
      <InformationItem>
        <b>Consumer Address:</b>{' '}
        <Link
          to={{
            pathname: `/accounts/${tq.account_id}/wallets/${
              consumption.address
            }`,
            search: location.search
          }}
        >
          {consumption.address}
        </Link>
      </InformationItem>
      <InformationItem>
        <b>Token:</b> <span>{_.get(consumption, 'token.name')}</span>
      </InformationItem>
      <InformationItem>
        <b>Amount:</b>{' '}
        <span>
          {formatReceiveAmountToTotal(
            consumption.estimated_consumption_amount,
            _.get(consumption, 'token.subunit_to_unit')
          )}{' '}
          {_.get(consumption, 'token.symbol')}
        </span>
      </InformationItem>
      <InformationItem>
        <b>Status:</b> <span>{consumption.status}</span>
      </InformationItem>
      {_.get(consumption, 'transaction.error_description') && (
        <InformationItem style={{ color: '#FC7166' }}>
          {_.get(consumption, 'transaction.error_description')}
        </InformationItem>
      )}
      {consumption.approved_at && (
        <InformationItem>
          <b>Approved Date:</b>{' '}
          <span>{moment(consumption.approved_at).format()}</span>
        </InformationItem>
      )}
      {consumption.rejected_at && (
        <InformationItem>
          <b>Rejected At:</b>{' '}
          <span>{moment(consumption.rejected_at).format()}</span>
        </InformationItem>
      )}
      {consumption.expired_at && (
        <InformationItem>
          <b>Expired Date:</b>{' '}
          <span>{moment(consumption.expired_at).format()}</span>
        </InformationItem>
      )}
      {consumption.status === 'pending' && (
        <InformationItem>
          <Button onClick={() => approveConsumptionById(consumption.id)}>
            <span>Approve</span>
          </Button>
          <Button
            onClick={() => rejectConsumptionById(consumption.id)}
            styleType='secondary'
          >
            <span>Reject</span>
          </Button>
          {consumption.user_id && (
            <Button
              onClick={() => cancelConsumptionById(consumption.id)}
              styleType='secondary'
            >
              <span>Cancel</span>
            </Button>
          )}
        </InformationItem>
      )}
    </ActionContainer>
  )
}

ConsumptionBox.propTypes = {
  consumption: PropTypes.object,
  location: PropTypes.object,
  cancelConsumptionById: PropTypes.func,
  rejectConsumptionById: PropTypes.func,
  approveConsumptionById: PropTypes.func
}

export default enhance(ConsumptionBox)
