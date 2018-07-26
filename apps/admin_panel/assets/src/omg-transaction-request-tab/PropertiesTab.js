import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import moment from 'moment'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import { withRouter } from 'react-router-dom'
import Link from '../omg-links'
import ConsumeBox from './ConsumeBox'
const InformationItem = styled.div`
  color: ${props => props.theme.colors.B200};
  :not(:last-child) {
    margin-bottom: 10px;
  }
  span {
    vertical-align: bottom;
  }
`
const TransactionReqeustPropertiesContainer = styled.div`
  height: calc(100vh - 160px);
  overflow: auto;
  b {
    font-weight: 600;
    color: ${props => props.theme.colors.B200};
  }
`

const AdditionalRequestDataContainer = styled.div`
  > div {
    margin-bottom: 10px;
  }
  h5 {
    margin-bottom: 10px;
    letter-spacing: 1px;
  }
`

class PropertiesTab extends Component {
  static propTypes = {
    match: PropTypes.object,
    transactionRequests: PropTypes.array
  }
  state = {}

  renderTransactionRequestDetail = () => {
    const tq = this.props.transactionRequests
    const amount =
      tq.amount === null ? (
        'Not Specified'
      ) : (
        <span>
          {formatReceiveAmountToTotal(tq.amount, _.get(tq, 'token.subunit_to_unit'))}{' '}
          {_.get(tq, 'token.symbol')}
        </span>
      )

    return (
      <AdditionalRequestDataContainer>
        <h5>ADDITIONAL REQUEST DETAILS</h5>
        <InformationItem>
          <b>Type :</b> {tq.type}
        </InformationItem>
        <InformationItem>
          <b>Token:</b> {_.get(tq, 'token.name')}
        </InformationItem>
        <InformationItem>
          <b>Amount :</b> {amount}
        </InformationItem>
        <InformationItem>
          <b>Requester Address : </b> <Link to={`/wallets/${tq.address}`}>{tq.address}</Link>
        </InformationItem>
        <InformationItem>
          <b>Account ID : </b>{' '}
          {_.get(tq, 'account.id') ? (
            <Link to={`/accounts/${_.get(tq, 'account.id')}`}>{_.get(tq, 'account.id')}</Link>
          ) : (
            '-'
          )}
        </InformationItem>
        <InformationItem>
          <b>Account Name : </b>{' '}
          {_.get(tq, 'account.id') ? (
            <Link to={`/accounts/${_.get(tq, 'account.id')}`}> {_.get(tq, 'account.name')} </Link>
          ) : (
            '-'
          )}
        </InformationItem>
        <InformationItem>
          <b>User ID : </b>{' '}
          {_.get(tq, 'user.id') ? (
            <Link to={`/users/${_.get(tq, 'user.id')}`}>{_.get(tq, 'user.id')}</Link>
          ) : (
            '-'
          )}
        </InformationItem>
        <InformationItem>
          <b>Confirmation : </b> {tq.require_confirmation ? 'Yes' : 'No'}
        </InformationItem>
        <InformationItem>
          <b>Consumptions Count : </b> {tq.current_consumptions_count}
        </InformationItem>
        <InformationItem>
          <b>Max Consumptions : </b> {tq.max_consumptions || '-'}
        </InformationItem>
        <InformationItem>
          <b>Max Consumptions Per User : </b> {tq.max_consumptions_per_user || '-'}
        </InformationItem>
        <InformationItem>
          <b>Expiry Date : </b>{' '}
          {tq.expiration_date
            ? moment(this.props.transactionRequests.expiration_date).format(
                'ddd, DD/MM/YYYY hh:mm:ss'
              )
            : '-'}
        </InformationItem>
        <InformationItem>
          <b>Allow Amount Override : </b> {tq.allow_amount_override ? 'Yes' : 'No'}
        </InformationItem>
        <InformationItem>
          <b>Coorelation ID : </b> {tq.correlation_id || '-'}
        </InformationItem>
      </AdditionalRequestDataContainer>
    )
  }
  render = () => {
    return (
      <TransactionReqeustPropertiesContainer>
        <ConsumeBox transactionRequests={this.props.transactionRequests} />
        {this.renderTransactionRequestDetail()}
      </TransactionReqeustPropertiesContainer>
    )
  }
}

export default withRouter(PropertiesTab)
