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
import { calculate } from '../omg-transaction/action'
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
  flex: 1 1 auto;
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
const AmountInput = styled(Input)`
  pointer-events: ${props => (props.override ? 'auto' : 'none')};
`
const RateCointaner = styled.div`
  color: ${props => props.theme.colors.B100};
`
class ConsumeBox extends Component {
  static propTypes = {
    transactionRequest: PropTypes.object,
    consumeTransactionRequest: PropTypes.func,
    match: PropTypes.object,
    calculate: PropTypes.func,
    selectTransactionRequestById: PropTypes.func,
    location: PropTypes.object
  }

  static getDerivedStateFromProps (props, state) {
    const transactionRequestId = queryString.parse(props.location.search)['show-request-tab']
    const transactionRequest = props.selectTransactionRequestById(transactionRequestId)
    if (!_.isEmpty(transactionRequest) && state.transactionRequestId !== transactionRequestId) {
      const amount = formatReceiveAmountToTotal(
        transactionRequest.amount,
        transactionRequest.token.subunit_to_unit
      )
      return {
        transactionRequestId,
        defaultAmount: amount || '',
        amount: amount || '',
        selectedToken: transactionRequest.token,
        searchTokenValue: transactionRequest.token.name,
        error: null,
        rate: null
      }
    }
    return null
  }

  state = { amount: '', searchTokenValue: '' }

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
    this.setState({ amount: e.target.value }, async () => {
      const transactionRequestId = queryString.parse(this.props.location.search)['show-request-tab']
      const transactionRequest = this.props.selectTransactionRequestById(transactionRequestId)
      const fromTokenId =
        transactionRequest.type === 'send'
          ? transactionRequest.token_id
          : this.state.selectedToken.id
      const toTokenId =
        transactionRequest.type === 'send'
          ? this.state.selectedToken.id
          : transactionRequest.token_id
      const amountTo = transactionRequest.allow_amount_override
        ? formatAmount(this.state.amount, transactionRequest.token.subunit_to_unit)
        : transactionRequest.amount
      let query = {
        fromTokenId,
        toTokenId
      }
      if (transactionRequest.type !== 'send') {
        Object.assign(query, { fromAmount: amountTo })
      } else {
        Object.assign(query, { toAmount: amountTo })
      }
      console.log(query)
      this.calculateRate(query)
    })
  }
  onSelectWalletAddressSelect = item => {
    this.setState({ consumeAddress: item.key })
  }
  onChangeSearchToken = e => {
    this.setState({ searchTokenValue: e.target.value })
  }
  onSelectTokenSelect = async token => {
    const oldToken = { ...this.state.selectedToken }
    this.setState({ searchTokenValue: token.name, selectedToken: token }, async () => {
      const transactionRequestId = queryString.parse(this.props.location.search)['show-request-tab']
      const transactionRequest = this.props.selectTransactionRequestById(transactionRequestId)
      if (transactionRequest.token.id === this.state.selectedToken.id) {
        this.setState({
          amount: formatReceiveAmountToTotal(
            transactionRequest.amount,
            transactionRequest.token.subunit_to_unit
          ),
          rate: null
        })
      } else if (oldToken.id !== this.state.selectedToken.id && this.state.amount) {
        const fromTokenId =
          transactionRequest.type === 'send' ? token.id : transactionRequest.token_id
        const toTokenId =
          transactionRequest.type === 'send' ? transactionRequest.token_id : token.id
        const amountTo = transactionRequest.allow_amount_override
          ? formatAmount(this.state.amount, transactionRequest.token.subunit_to_unit)
          : transactionRequest.amount
        let query = {
          fromTokenId,
          toTokenId
        }
        if (transactionRequest.type === 'send') {
          Object.assign(query, { toAmount: amountTo })
        } else {
          Object.assign(query, { fromAmount: amountTo })
        }
        const rate = await this.calculateRate(query)
        const amount =
          transactionRequest.type !== 'send'
            ? formatReceiveAmountToTotal(
                rate.to_amount,
                _.get(rate, 'exchange_pair.to_token.subunit_to_unit')
              )
            : formatReceiveAmountToTotal(
                rate.from_amount,
                _.get(rate, 'exchange_pair.from_token.subunit_to_unit')
              )
        this.setState({ amount })
      }
    })
  }
  calculateRate = async ({ fromTokenId, toTokenId, fromAmount, toAmount }) => {
    if (fromTokenId !== toTokenId) {
      try {
        const { data, error } = await this.props.calculate({
          fromTokenId,
          toTokenId,
          fromAmount,
          toAmount
        })
        if (data) {
          this.setState({ error: null, rate: data })
          return data
        } else {
          this.setState({
            error: error.description || 'Exchange pair does not exist.',
            rate: null
          })
        }
      } catch (error) {
        this.setState({ error: `${error}`, rate: null })
      }
    } else {
      this.setState({ error: null })
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

  render = () => {
    const valid = this.props.transactionRequest.status === 'valid'
    return (
      <ConsumeActionContainer onSubmit={this.onSubmitConsume(this.props.transactionRequest)}>
        <QrContainer>
          <QR data={this.props.transactionRequest.id} />
          <QrTypeContainer>
            <b>Type : </b>
            <div>{this.props.transactionRequest.type}</div>
          </QrTypeContainer>
          <QrTypeContainer>
            <b>Token :</b>
            <div>{_.get(this.props.transactionRequest, 'token.name')}</div>
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
                    <AmountInput
                      override={this.props.transactionRequest.allow_amount_override}
                      normalPlaceholder='1000'
                      onChange={this.onChangeAmount}
                      value={this.state.amount}
                      type='amount'
                      disabled={!valid}
                    />
                  </InputLabelContainer>
                  <InputLabelContainer>
                    <InputLabel disabled={!valid}>
                      Token to{' '}
                      {this.props.transactionRequest.type === 'receive' ? 'send' : 'receive'}
                    </InputLabel>
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
          {this.state.rate && (
            <RateCointaner>
              {formatReceiveAmountToTotal(
                _.get(this.state, 'rate.from_amount'),
                _.get(this.state, 'rate.exchange_pair.from_token.subunit_to_unit')
              )}{' '}
              {_.get(this.state, 'rate.exchange_pair.from_token.symbol')} ={' '}
              {formatReceiveAmountToTotal(
                _.get(this.state, 'rate.to_amount'),
                _.get(this.state, 'rate.exchange_pair.to_token.subunit_to_unit')
              )}{' '}
              {_.get(this.state, 'rate.exchange_pair.to_token.symbol')}
            </RateCointaner>
          )}
          {this.props.transactionRequest.expiration_reason ? (
            <ExpiredContainer>
              {this.getExpiredReason(this.props.transactionRequest.expiration_reason)}
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
    { consumeTransactionRequest, calculate }
  )(ConsumeBox)
)
