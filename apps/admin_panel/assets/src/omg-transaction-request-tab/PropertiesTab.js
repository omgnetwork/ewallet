import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import moment from 'moment'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import { Link, withRouter } from 'react-router-dom'
import ConsumeBox from './ConsumeBox'
const InformationItem = styled.div`
  color: ${props => props.theme.colors.B200};
  :not(:last-child) {
    margin-bottom: 10px;
  }
  span {
    vertical-align: baseline;
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
    const amount =
      this.props.transactionRequests.amount === null ? (
        'Not Specified'
      ) : (
        <span>
          {formatReceiveAmountToTotal(
            this.props.transactionRequests.amount,
            _.get(this.props.transactionRequests, 'token.subunit_to_unit')
          )}{' '}
          {_.get(this.props.transactionRequests, 'token.symbol')}
        </span>
      )
    return (
      <AdditionalRequestDataContainer>
        <h5>ADDITIONAL REQUEST DETAILS</h5>
        <InformationItem>
          <b>Type :</b> {this.props.transactionRequests.type}
        </InformationItem>
        <InformationItem>
          <b>Token:</b> {_.get(this.props.transactionRequests, 'token.name')}
        </InformationItem>
        <InformationItem>
          <b>Amount :</b> {amount}
        </InformationItem>
        <InformationItem>
          <b>Requester Address : </b>{' '}
          <Link
            to={`/${this.props.match.params.accountId}/wallet/${
              this.props.transactionRequests.address
            }`}
          >
            {this.props.transactionRequests.address}
          </Link>
        </InformationItem>
        <InformationItem>
          <b>Account ID : </b> {_.get(this.props.transactionRequests, 'account.id', '-')}
        </InformationItem>
        <InformationItem>
          <b>Account Name : </b>{' '}
          {_.get(this.props.transactionRequests, 'account.id') ? (
            <Link
              to={`/${this.props.match.params.accountId}/wallet/${
                this.props.transactionRequests.address
              }`}
            >
              {' '}
              {this.props.transactionRequests.account.name}{' '}
            </Link>
          ) : (
            '-'
          )}
        </InformationItem>
        <InformationItem>
          <b>User ID : </b> {_.get(this.props.transactionRequests, 'user.id', '-')}
        </InformationItem>
        <InformationItem>
          <b>Confirmation : </b>{' '}
          {this.props.transactionRequests.require_confirmation ? 'Yes' : 'No'}
        </InformationItem>
        <InformationItem>
          <b>Consumptions Count : </b> {this.props.transactionRequests.current_consumptions_count}
        </InformationItem>
        <InformationItem>
          <b>Max Consumptions : </b> {this.props.transactionRequests.max_consumptions || '-'}
        </InformationItem>
        <InformationItem>
          <b>Max Consumptions Per User : </b>{' '}
          {this.props.transactionRequests.max_consumptions_per_user || '-'}
        </InformationItem>
        <InformationItem>
          <b>Expiry Date : </b>{' '}
          {this.props.transactionRequests.expiration_date
            ? moment(this.props.transactionRequests.expiration_date).format(
                'ddd, DD/MM/YYYY hh:mm:ss'
              )
            : '-'}
        </InformationItem>
        <InformationItem>
          <b>Allow Amount Override : </b>{' '}
          {this.props.transactionRequests.allow_amount_override ? 'Yes' : 'No'}
        </InformationItem>
        <InformationItem>
          <b>Coorelation ID : </b> {this.props.transactionRequests.correlation_id || '-'}
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
