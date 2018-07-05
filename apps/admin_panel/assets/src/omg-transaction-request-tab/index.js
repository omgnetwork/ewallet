import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import TabPanel from './TabPanel'
import TransactionRequestProvider from '../omg-transaction-request/transactionRequestProvider'
import { Icon, Button, Select, Input } from '../omg-uikit'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
import QR from './QrCode'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { formatRecieveAmountToTotal, formatAmount } from '../utils/formatter'
import AllWalletsFetcher from '../omg-wallet/allWalletsFetcher'
import TokensFetcher from '../omg-token/tokensFetcher'
import { consumeTransactionRequest } from '../omg-transaction-request/action'
import { selectGetTransactionRequestById } from '../omg-transaction-request/selector'
import { selectPendingConsumptions } from '../omg-consumption/selector'
import ActivityList from './ActivityList'
const PanelContainer = styled.div`
  height: 100vh;
  position: fixed;
  right: 0;
  width: 560px;
  background-color: white;
  padding: 40px 30px;
  box-shadow: 0 0 15px 0 rgba(4, 7, 13, 0.1);
  > i {
    position: absolute;
    right: 0;
    color: ${props => props.theme.colors.S500};
    top: 0;
    cursor: pointer;
    padding: 20px;
  }
`

const ConsumeActionContainer = styled.form`
  display: flex;
  margin: 20px 0;
  border: 1px solid ${props => props.theme.colors.S300};
  border-radius: 4px;
  background-color: ${props => props.theme.colors.S100};
  position: relative;
`
const TokenAmountContainer = styled.div`
  display: flex;
  > div:first-child {
    padding-right: 20px;
  }
`
const InformationItem = styled.div`
  color: ${props => props.theme.colors.B200};
  :not(:last-child) {
    margin-bottom: 10px;
  }
`
const QrContainer = styled.div`
  background-color: white;
  padding: 20px;
  > img {
    width: 100px;
    height: 100px;
    margin: -10px;
  }
  > div {
    color: ${props => props.theme.colors.B300};
  }
`
const InputsContainer = styled.div`
  flex: 1 1 auto;
  padding: 20px;
  text-align: right;
  > div:not(:last-child) {
    margin-bottom: 20px;
  }
  > div:nth-child(3) {
    margin-top: 32px;
    margin-bottom: 0;
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
const AdditionalRequestDataContainer = styled.div`
  > div {
    margin-bottom: 10px;
  }
  h5 {
    margin-bottom: 10px;
    letter-spacing: 1px;
  }
`

const QrTypeContainer = styled.div`
  margin-top: 15px;
  :not(:last-child) {
    margin-bottom: 10px;
  }
  > div {
    color: ${props => props.theme.colors.B300};
  }
`

const InputLabel = styled.div`
  margin-top: 20px;
  font-size: 14px;
  font-weight: 400;
  color: ${props => (props.disabled ? props.theme.colors.S400 : props.theme.colors.B300)};
`
const InputLabelContainer = styled.div`
  text-align: left;
`
const ExpiredContainer = styled.div`
  background-color: ${props => props.theme.colors.S200};
  color: ${props => props.theme.colors.S500};
  border-radius: 4px;
  padding: 5px 10px;
  text-align: center;
`

const Error = styled.div`
  color: ${props => props.theme.colors.R400};
  padding: ${props => (props.error ? '10px 0' : 0)};
  overflow: hidden;
  max-height: ${props => (props.error ? '50px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
  text-align: right;
`
const RedDot = styled.div`
  display: inline-block;
  margin-left: 3px;
  background-color: ${props => props.theme.colors.R300};
  width: 7px;
  height: 7px;
  border-radius: 50%;
  vertical-align: middle;
  visibility: ${props => (props.show ? 'visible' : 'hidden')};
`
const enhance = compose(
  withRouter,
  connect(
    (state, props) => ({
      selectTransactionRequestById: selectGetTransactionRequestById(state),
      pendingConsumptions: selectPendingConsumptions(
        queryString.parse(props.location.search)['show-request-tab']
      )(state)
    }),
    { consumeTransactionRequest }
  )
)

class TransactionRequestPanel extends Component {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object,
    consumeTransactionRequest: PropTypes.func,
    selectTransactionRequestById: PropTypes.func,
    pendingConsumptions: PropTypes.array
  }

  static getDerivedStateFromProps (props, state) {
    const transactionRequestId = queryString.parse(props.location.search)['show-request-tab']
    const transactionRequest = props.selectTransactionRequestById(transactionRequestId)
    if (!_.isEmpty(transactionRequest) && state.transactionRequestId !== transactionRequestId) {
      return {
        transactionRequestId,
        amount: formatRecieveAmountToTotal(
          transactionRequest.amount,
          transactionRequest.token.subunit_to_unit
        ),
        selectedToken: transactionRequest.token,
        searchTokenValue: `${transactionRequest.token.name} (${transactionRequest.token.symbol})`
      }
    }
    return null
  }

  constructor (props) {
    super(props)
    this.state = {
      consumeAddress: '',
      amount: 0,
      searchTokenValue: ''
    }
  }

  onChangeWalletInput = e => {
    this.setState({ consumeAddress: e.target.value })
  }
  onChangeAmount = e => {
    this.setState({ amount: e.target.value })
  }
  onSelectWalletAddressSelect = item => {
    this.setState({ consumeAddress: item.key })
  }
  onChangeSearchToken = e => {
    this.setState({ searchTokenValue: e.target.value, selectedToken: null })
  }
  onSelectTokenSelect = token => {
    this.setState({ searchTokenValue: token.value, selectedToken: token })
  }

  onClickClose = () => {
    const searchObject = queryString.parse(this.props.location.search)
    delete searchObject['active-tab']
    delete searchObject['show-request-tab']
    delete searchObject['page-activity']
    this.props.history.push({
      search: queryString.stringify(searchObject)
    })
  }
  onClickTab = tab => e => {
    const searchObject = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        [`active-tab`]: tab
      })
    })
  }
  onSubmitConsume = transactionRequest => async e => {
    e.preventDefault()
    this.setState({ submitStatus: 'SUBMITTING' })
    try {
      const result = await this.props.consumeTransactionRequest({
        formattedTransactionRequestId: transactionRequest.id,
        tokenId: this.state.selectedToken.id,
        amount: transactionRequest.allow_amount_override
          ? formatAmount(this.state.amount, _.get(this.state.selectedToken, 'subunit_to_unit'))
          : null,
        address: this.state.consumeAddress
      })
      if (result.data) {
        this.setState({ submitStatus: 'SUCCESS', error: null })
      } else {
        this.setState({ submitStatus: 'FAILED', error: result.error.description })
      }
    } catch (error) {
      this.setState({ submitStatus: 'FAILED', error: `${error}` })
    }
  }

  getExpiredReason = reason => {
    switch (reason) {
      case 'max_consumptions_reached':
        return 'Max consumptions reached.'
      case 'expired_transaction_request':
        return 'Transaction Expired.'
      default:
        return 'Expired.'
    }
  }

  renderProperties = transactionRequest => {
    const valid = transactionRequest.status === 'valid'
    return (
      <TransactionReqeustPropertiesContainer>
        <ConsumeActionContainer onSubmit={this.onSubmitConsume(transactionRequest)}>
          <QrContainer>
            <QR data={transactionRequest.id} />
            <QrTypeContainer>
              <b>Type : </b>
              <div>{transactionRequest.type}</div>
            </QrTypeContainer>
            <QrTypeContainer>
              <b>Token :</b>
              <div>{_.get(transactionRequest, 'token.name')}</div>
            </QrTypeContainer>
          </QrContainer>
          <InputsContainer>
            <AllWalletsFetcher
              query={{ search: this.state.consumeAddress }}
              render={({ data }) => {
                return (
                  <InputLabelContainer>
                    <InputLabel disabled={!valid}>Wallet</InputLabel>
                    <Select
                      disabled={!valid}
                      normalPlaceholder='acc_0x000000000000000'
                      onSelectItem={this.onSelectWalletAddressSelect}
                      value={this.state.consumeAddress}
                      onChange={this.onChangeWalletInput}
                      options={data.map(d => {
                        return {
                          key: d.address,
                          value: `${d.address} ( ${_.get(d, 'account.name') ||
                            _.get(d, 'user.username') ||
                            _.get(d, 'user.email')} )`
                        }
                      })}
                    />
                  </InputLabelContainer>
                )
              }}
            />
            <TokensFetcher
              render={({ data }) => {
                return (
                  <TokenAmountContainer>
                    <InputLabelContainer>
                      <InputLabel disabled={!valid}>Amount</InputLabel>
                      <Input
                        normalPlaceholder='1000'
                        onChange={this.onChangeAmount}
                        value={this.state.amount}
                        type='number'
                        disabled={!valid || !transactionRequest.allow_amount_override}
                      />
                    </InputLabelContainer>
                    <InputLabelContainer>
                      <InputLabel disabled={!valid}>Token</InputLabel>
                      <Select
                        disabled={!valid}
                        normalPlaceholder='ETH'
                        onSelectItem={this.onSelectTokenSelect}
                        onChange={this.onChangeSearchToken}
                        value={this.state.searchTokenValue}
                        options={data.map(token => ({
                          ...{
                            key: `${token.symbol}${token.name}${token.id}`,
                            value: `${token.name} (${token.symbol})`
                          },
                          ...token
                        }))}
                      />
                    </InputLabelContainer>
                  </TokenAmountContainer>
                )
              }}
            />
            {transactionRequest.expiration_reason ? (
              <ExpiredContainer>
                {this.getExpiredReason(transactionRequest.expiration_reason)}
              </ExpiredContainer>
            ) : (
              <Button disabled={!valid} loading={this.state.submitStatus === 'SUBMITTING'}>
                Consume
              </Button>
            )}
            <Error error={this.state.error}>{this.state.error}</Error>
          </InputsContainer>
        </ConsumeActionContainer>
        <AdditionalRequestDataContainer>
          <h5>ADDITIONAL REQUEST DETAILS</h5>
          <InformationItem>
            <b>Type :</b> {transactionRequest.type}
          </InformationItem>
          <InformationItem>
            <b>Token ID :</b> {_.get(transactionRequest, 'token.id')}
          </InformationItem>
          <InformationItem>
            <b>Amount :</b>{' '}
            {formatRecieveAmountToTotal(
              transactionRequest.amount,
              _.get(transactionRequest, 'token.subunit_to_unit')
            )}{' '}
            {_.get(transactionRequest, 'token.symbol')}
          </InformationItem>
          <InformationItem>
            <b>Requester Address : </b> {transactionRequest.address}
          </InformationItem>
          <InformationItem>
            <b>Confirmation : </b> {transactionRequest.require_confirmation ? 'Yes' : 'No'}
          </InformationItem>
          <InformationItem>
            <b>Consumptions Count : </b> {transactionRequest.current_consumptions_count}
          </InformationItem>
          <InformationItem>
            <b>Max Consumptions : </b> {transactionRequest.max_consumptions || '-'}
          </InformationItem>
          <InformationItem>
            <b>Max Consumptions User : </b> {transactionRequest.max_consumptions_per_user || '-'}
          </InformationItem>
          <InformationItem>
            <b>Expiry Date : </b> {transactionRequest.expiration_date || '-'}
          </InformationItem>
          <InformationItem>
            <b>Allow Amount Override : </b>{' '}
            {transactionRequest.allow_amount_override ? 'Yes' : 'No'}
          </InformationItem>
          <InformationItem>
            <b>Coorelation ID : </b> {transactionRequest.correlation_id || '-'}
          </InformationItem>
        </AdditionalRequestDataContainer>
      </TransactionReqeustPropertiesContainer>
    )
  }

  render = () => {
    return (
      <TransactionRequestProvider
        transactionRequestId={queryString.parse(this.props.location.search)['show-request-tab']}
        render={({ transactionRequest: tq }) => {
          return (
            <PanelContainer>
              <Icon name='Close' onClick={this.onClickClose} />
              <h4>
                Request to {tq.type}{' '}
                {formatRecieveAmountToTotal(tq.amount, _.get(tq, 'token.subunit_to_unit'))}{' '}
                {_.get(tq, 'token.symbol')}
              </h4>
              <SubDetailTitle>
                <span>{tq.type}</span> | <span>{tq.user_id || _.get(tq, 'account.name')}</span>
              </SubDetailTitle>
              <TabPanel
                activeTabKey={
                  queryString.parse(this.props.location.search)['active-tab'] || 'activity'
                }
                onClickTab={this.onClickTab}
                data={[
                  {
                    key: 'activity',
                    tabTitle: (
                      <div style={{ marginLeft: '5px' }}>
                        <span>PENDING CONSUMPTION</span>{' '}
                        <RedDot show={!!this.props.pendingConsumptions.length} />
                      </div>
                    ),
                    tabContent: <ActivityList />
                  },
                  {
                    key: 'properties',
                    tabTitle: 'PROPERTIES',
                    tabContent: this.renderProperties(tq)
                  }
                ]}
              />
            </PanelContainer>
          )
        }}
      />
    )
  }
}

export default enhance(TransactionRequestPanel)
