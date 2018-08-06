import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import ConsumptionProvider from '../omg-consumption/consumptionProvider'
import { Icon, Button } from '../omg-uikit'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
import { connect } from 'react-redux'
import { approveConsumptionById, rejectConsumptionById } from '../omg-consumption/action'
import { compose } from 'recompose'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import Link from '../omg-links'
import moment from 'moment'
import TransactionRequestDetail from '../omg-transaction-request-tab/TransactionRequestDetail'
const PanelContainer = styled.div`
  height: 100vh;
  position: fixed;
  right: 0;
  width: 560px;
  background-color: white;
  overflow: auto;
  padding: 40px 30px;
  box-shadow: 0 0 15px 0 rgba(4, 7, 13, 0.1);
  > i {
    position: absolute;
    right: 25px;
    color: ${props => props.theme.colors.S500};
    top: 25px;
    cursor: pointer;
  }
`
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
const SubDetailTitle = styled.div`
  margin-top: 10px;
  color: ${props => props.theme.colors.B100};
  margin-bottom: 10px;
  > span {
    padding: 0 5px;
    :first-child {
      padding-left: 0;
    }
  }
`
const enhance = compose(
  withRouter,
  connect(
    null,
    { approveConsumptionById, rejectConsumptionById }
  )
)
class TransactionRequestPanel extends Component {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object,
    approveConsumptionById: PropTypes.func,
    rejectConsumptionById: PropTypes.func,
    match: PropTypes.object
  }

  constructor (props) {
    super(props)
    this.state = {}
  }
  onClickClose = () => {
    const searchObject = queryString.parse(this.props.location.search)
    delete searchObject['show-consumption-tab']
    this.props.history.push({
      search: queryString.stringify(searchObject)
    })
  }
  render = () => {
    return (
      <ConsumptionProvider
        consumptionId={queryString.parse(this.props.location.search)['show-consumption-tab']}
        render={({ consumption }) => {
          const tq = consumption.transaction_request || {}
          return (
            <PanelContainer>
              <Icon name='Close' onClick={this.onClickClose} />
              <h4>Consumption</h4>
              <SubDetailTitle>
                <span>{consumption.id}</span> | <span>{tq.type}</span>
              </SubDetailTitle>
              <ActionContainer>
                <InformationItem>
                  <b>Request:</b>{' '}
                  <span>
                    <Link to={{ search: `show-request-tab=${tq.id}` }}>{tq.id}</Link>
                  </span>
                </InformationItem>
                <InformationItem>
                  <b>Type:</b> <span>{tq.type}</span>
                </InformationItem>
                <InformationItem>
                  <b>Requester Address:</b> <Link to={`/wallets/${tq.address}`}>{tq.address}</Link>
                </InformationItem>
                <InformationItem>
                  <b>Consumer Address:</b>{' '}
                  <Link to={`/wallets/${consumption.address}`}>{consumption.address}</Link>
                </InformationItem>
                <InformationItem>
                  <b>Token:</b> <span>{_.get(tq, 'token.name')}</span>
                </InformationItem>
                <InformationItem>
                  <b>Amount:</b>{' '}
                  <span>
                    {formatReceiveAmountToTotal(
                      consumption.estimated_consumption_amount,
                      _.get(consumption, 'token.subunit_to_unit')
                    )}{' '}
                    {_.get(tq, 'token.symbol')}
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
                    <span>
                      {moment(consumption.approved_at).format('ddd, DD/MM/YYYY hh:mm:ss')}
                    </span>
                  </InformationItem>
                )}
                {consumption.rejected_at && (
                  <InformationItem>
                    <b>Rejected At:</b>{' '}
                    <span>
                      {moment(consumption.rejected_at).format('ddd, DD/MM/YYYY hh:mm:ss')}
                    </span>
                  </InformationItem>
                )}
                {consumption.expired_at && (
                  <InformationItem>
                    <b>Expired Date:</b>{' '}
                    <span>{moment(consumption.expired_at).format('ddd, DD/MM/YYYY hh:mm:ss')}</span>
                  </InformationItem>
                )}
                {consumption.status === 'pending' && (
                  <InformationItem>
                    <Button onClick={() => this.props.approveConsumptionById(consumption.id)}>
                      Approve
                    </Button>
                    <Button
                      onClick={() => this.props.rejectConsumptionById(consumption.id)}
                      styleType='secondary'
                    >
                      Reject
                    </Button>
                  </InformationItem>
                )}
              </ActionContainer>
              <TransactionRequestDetail transactionRequest={tq} />
            </PanelContainer>
          )
        }}
      />
    )
  }
}

export default enhance(TransactionRequestPanel)
