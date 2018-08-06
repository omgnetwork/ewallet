import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import WalletsFetcher from '../omg-wallet/walletsFetcher'
import TokensFetcher from '../omg-token/tokensFetcher'
import QR from './QrCode'
import { formatAmount, formatReceiveAmountToTotal } from '../utils/formatter'
import { Select, Button, Input } from '../omg-uikit'
import { withRouter } from 'react-router-dom'
import { connect } from 'react-redux'
import { consumeTransactionRequest } from '../omg-transaction-request/action'
import queryString from 'query-string'
import { selectGetTransactionRequestById } from '../omg-transaction-request/selector'
import WalletSelect from '../omg-wallet-select'
import TokenSelect from '../omg-token-select'
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
  max-height: ${props => (props.error ? '100px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
  text-align: right;
`
class PropertiesTab extends Component {
  static propTypes = {
    transactionRequests: PropTypes.array,
    consumeTransactionRequest: PropTypes.func,
    match: PropTypes.object
  }

  static getDerivedStateFromProps (props, state) {
    const transactionRequestId = queryString.parse(props.location.search)['show-request-tab']
    const transactionRequest = props.selectTransactionRequestById(transactionRequestId)
    if (!_.isEmpty(transactionRequest) && state.transactionRequestId !== transactionRequestId) {
      return {
        transactionRequestId,
        amount: formatReceiveAmountToTotal(
          transactionRequest.amount,
          transactionRequest.token.subunit_to_unit
        ),
        selectedToken: transactionRequest.token,
        searchTokenValue: transactionRequest.token.name,
        error: null
      }
    }
    return null
  }
  state = {}

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
        this.setState({
          submitStatus: 'FAILED',
          error: result.error.description || result.error.message
        })
      }
    } catch (error) {
      this.setState({ submitStatus: 'FAILED', error: `${error}` })
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
    this.setState({ searchTokenValue: token.name, selectedToken: token })
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

  render = () => {
    const valid = this.props.transactionRequests.status === 'valid'
    return (
      <ConsumeActionContainer onSubmit={this.onSubmitConsume(this.props.transactionRequests)}>
        <QrContainer>
          <QR data={this.props.transactionRequests.id} />
          <QrTypeContainer>
            <b>Type : </b>
            <div>{this.props.transactionRequests.type}</div>
          </QrTypeContainer>
          <QrTypeContainer>
            <b>Token :</b>
            <div>{_.get(this.props.transactionRequests, 'token.name')}</div>
          </QrTypeContainer>
        </QrContainer>
        <InputsContainer>
          <WalletsFetcher
            query={{ search: this.state.consumeAddress }}
            accountId={this.props.match.params.accountId}
            owned={false}
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
                        value: <WalletSelect wallet={d} />,
                        ...d
                      }
                    })}
                  />
                </InputLabelContainer>
              )
            }}
          />
          <TokensFetcher
            query={{ search: this.state.searchTokenValue }}
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
                      disabled={!valid || !this.props.transactionRequests.allow_amount_override}
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
                        key: `${token.symbol}${token.name}${token.id}`,
                        value: <TokenSelect token={token} />,
                        ...token
                      }))}
                    />
                  </InputLabelContainer>
                </TokenAmountContainer>
              )
            }}
          />
          {this.props.transactionRequests.expiration_reason ? (
            <ExpiredContainer>
              {this.getExpiredReason(this.props.transactionRequests.expiration_reason)}
            </ExpiredContainer>
          ) : (
            <Button disabled={!valid} loading={this.state.submitStatus === 'SUBMITTING'}>
              Consume
            </Button>
          )}
          <Error error={this.state.error}>{this.state.error}</Error>
        </InputsContainer>
      </ConsumeActionContainer>
    )
  }
}

export default withRouter(
  connect(
    state => ({ selectTransactionRequestById: selectGetTransactionRequestById(state) }),
    { consumeTransactionRequest }
  )(PropertiesTab)
)
