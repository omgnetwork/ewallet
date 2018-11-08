import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input, Button, Icon, Select } from '../omg-uikit'
import Modal from '../omg-modal'
import { transfer } from '../omg-transaction/action'
import { getWalletById } from '../omg-wallet/action'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import { formatReceiveAmountToTotal, formatAmount } from '../utils/formatter'
import WalletsFetcher from '../omg-wallet/walletsFetcher'
import AllWalletsFetcher from '../omg-wallet/allWalletsFetcher'
import WalletSelect from '../omg-wallet-select'
import { selectWalletById } from '../omg-wallet/selector'
import TokenSelect from '../omg-token-select'
import { createSearchAddressQuery } from '../omg-wallet/searchField'
const Form = styled.form`
  width: 100vw;
  height: 100vh;
  position: relative;
  > i {
    position: absolute;
    right: 30px;
    top: 30px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
    font-size: 30px;
  }
  input {
    margin-top: 5px;
  }
  button {
    margin: 35px 0 0;
    font-size: 14px;
    padding-left: 40px;
    padding-right: 40px;
  }
  h4 {
    text-align: center;
    margin-bottom: 40px;
    font-size: 18px;
  }
`
const InputLabel = styled.div`
  margin-top: 20px;
  font-size: 14px;
  font-weight: 400;
`
const ButtonContainer = styled.div`
  text-align: center;
`
const BalanceTokenLabel = styled.div`
  font-size: 12px;
  color: ${props => props.theme.colors.B100};
  margin-top: 5px;
`
const Error = styled.div`
  color: ${props => props.theme.colors.R400};
  text-align: center;
  padding: 10px 0;
  overflow: hidden;
  max-height: ${props => (props.error ? '100px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
`
const InputGroupContainer = styled.div`
  display: flex;
  > div:first-child {
    flex: 1 1 auto;
    margin-right: 40px;
  }
`
const OptionalExplanation = styled.div`
  margin-top: 10px;
  font-size: 10px;
  color: ${props => props.theme.colors.B100};
`
const FromToContainer = styled.div`
  h5 {
    letter-spacing: 1px;
    background-color: ${props => props.theme.colors.S300};
    display: inline-block;
    padding: 5px 10px;
  }
`
const InnerTransferContainer = styled.div`
  max-width: 600px;
  padding: 50px;
  margin: 0 auto;
`
const enhance = compose(
  withRouter,
  connect(
    state => ({ selectWalletById: selectWalletById(state) }),
    { transfer, getWalletById }
  )
)
class CreateTransaction extends Component {
  static propTypes = {
    onRequestClose: PropTypes.func,
    fromAddress: PropTypes.string,
    selectWalletById: PropTypes.func,
    getWalletById: PropTypes.func,
    match: PropTypes.object,
    onCreateTransaction: PropTypes.func
  }
  static defaultProps = {
    onCreateTransaction: _.noop
  }
  state = { fromAddress: this.props.fromAddress || '', toAddress: '' }

  onChangeInputFromAddress = e => {
    this.setState({
      fromAddress: e.target.value,
      fromTokenSelected: null,
      fromTokenSearchToken: ''
    })
  }
  onChangeInputToAddress = e => {
    this.setState({
      toAddress: e.target.value,
      toTokenSelected: null,
      toTokenSearchToken: ''
    })
  }
  onChangeInputExchangeAddress = e => {
    this.setState({
      exchangeAddress: e.target.value
    })
  }
  onChangeAmount = type => e => {
    this.setState({ [`${type}Amount`]: e.target.value })
  }
  onChangeSearchToken = type => e => {
    this.setState({ [`${type}SearchToken`]: e.target.value, [`${type}Selected`]: null })
  }
  onSelectTokenSelect = type => token => {
    this.setState({ [`${type}SearchToken`]: _.get(token, 'token.name'), [`${type}Selected`]: token })
  }
  onSelectToAddressSelect = item => {
    this.setState({
      toAddress: item.key,
      toTokenSelected: this.state.toTokenSelected ? item.balances.find(b => b.token.id === _.get(this.state.toTokenSelected, 'token.id')) : null
    })
  }
  onSelectFromAddressSelect = item => {
    this.setState({
      fromAddress: item.key,
      fromTokenSelected: this.state.fromTokenSelected ? item.balances.find(b => b.token.id === _.get(this.state.fromTokenSelected, 'token.id')) : null
    })
  }
  onSelectExchangeAddressSelect = item => {
    this.setState({ exchangeAddress: item.key })
  }
  onFocusSelect = type => () => {
    this.setState({ [`${type}SearchToken`]: '', [`${type}Selected`]: null })
  }

  onFocusFromAddressSelect = () => {
    this.setState({ fromAddress: '' })
  }
  onFocusToAddressSelect = () => {
    this.setState({ toAddress: '' })
  }
  onFocusExchangeAddressSelect = () => {
    this.setState({ exchangeAddress: '' })
  }
  onBlurFromAddressSelect = () => {
    if (!this.state.fromAddress) {
      this.setState({ fromTokenSearchToken: '', fromTokenSelected: null })
    }
  }
  onBlurToAddressSelect = () => {
    if (!this.state.toAddress) {
      this.setState({ toTokenSearchToken: '', toTokenSelected: null })
    }
  }

  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const fromAmount = formatAmount(this.state.fromTokenAmount, _.get(this.state.fromTokenSelected, 'token.subunit_to_unit'))
      const toAmount = formatAmount(this.state.toTokenAmount, _.get(this.state.toTokenSelected, 'token.subunit_to_unit'))
      const result = await this.props.transfer({
        fromAddress: this.state.fromAddress.trim(),
        toAddress: this.state.toAddress.trim(),
        fromTokenId: _.get(this.state.fromTokenSelected, 'token.id'),
        toTokenId: _.get(this.state.toTokenSelected, 'token.id') || _.get(this.state.fromTokenSelected, 'token.id'),
        fromAmount,
        toAmount,
        exchangeAddress: this.state.exchangeAddress
      })
      if (result.data) {
        this.props.getWalletById(this.state.fromAddress)
        this.props.getWalletById(this.state.toAddress)
        this.onRequestClose()
      } else {
        this.setState({
          submitting: false,
          error: result.error.description || result.error.message
        })
      }
      this.props.onCreateTransaction()
    } catch (e) {
      this.setState({ error: JSON.stringify(e.message) })
    }
  }

  onRequestClose = () => {
    this.props.onRequestClose()
    this.setState({ submitting: false })
  }

  getBalanceOfSelectedToken = type => {
    return this.state[`${type}Selected`]
      ? formatReceiveAmountToTotal(_.get(this.state[`${type}Selected`], 'amount'), _.get(this.state[`${type}Selected`], 'token.subunit_to_unit'))
      : '-'
  }

  renderFromSection () {
    const fromWallet = this.props.selectWalletById(this.state.fromAddress.trim())
    return (
      <FromToContainer>
        <h5>From</h5>
        <InputLabel>From Address</InputLabel>
        <WalletsFetcher
          accountId={this.props.match.params.accountId}
          owned={false}
          query={createSearchAddressQuery(this.state.fromAddress)}
          render={({ data, individualLoadingStatus }) => {
            return (
              <Select
                normalPlaceholder='acc_0x000000000000000'
                onSelectItem={this.onSelectFromAddressSelect}
                value={this.state.fromAddress}
                onChange={this.onChangeInputFromAddress}
                onBlur={this.onBlurFromAddressSelect}
                options={data.filter(w => w.identifier !== 'burn').map(d => {
                  return {
                    key: d.address,
                    value: <WalletSelect wallet={d} />,
                    ...d
                  }
                })}
              />
            )
          }}
        />
        <InputGroupContainer>
          <div>
            <InputLabel>Token</InputLabel>
            <Select
              normalPlaceholder='Token'
              onSelectItem={this.onSelectTokenSelect('fromToken')}
              onChange={this.onChangeSearchToken('fromToken')}
              value={this.state.fromTokenSearchToken}
              options={
                fromWallet
                  ? fromWallet.balances.map(b => ({
                    key: `${b.token.name}${b.token.symbol}${b.token.id}`,
                    value: <TokenSelect token={b.token} />,
                    ...b
                  }))
                  : []
              }
            />
            <BalanceTokenLabel>Balance: {this.getBalanceOfSelectedToken('fromToken')}</BalanceTokenLabel>
          </div>
          <div>
            <InputLabel>Amount</InputLabel>
            <Input value={this.state.fromTokenAmount} onChange={this.onChangeAmount('fromToken')} type='amount' normalPlaceholder={'Token amount'} />
          </div>
        </InputGroupContainer>
      </FromToContainer>
    )
  }
  renderToSection () {
    const toWallet = this.props.selectWalletById(this.state.toAddress.trim())
    return (
      <FromToContainer>
        <h5 style={{ marginTop: '20px' }}>To</h5>
        <InputLabel>To Address</InputLabel>
        <AllWalletsFetcher
          query={createSearchAddressQuery(this.state.toAddress)}
          render={({ data }) => {
            return (
              <Select
                normalPlaceholder='acc_0x000000000000000'
                onSelectItem={this.onSelectToAddressSelect}
                value={this.state.toAddress}
                onChange={this.onChangeInputToAddress}
                onBlur={this.onBlurToAddressSelect}
                options={data.map(d => {
                  return { key: d.address, value: <WalletSelect wallet={d} />, ...d }
                })}
              />
            )
          }}
        />
        <div>
          <OptionalExplanation>
            The fields below are optional and should only be used if you want to perform an exchange. Leave the amount blank to let the server use the
            default exchange rate.
          </OptionalExplanation>
          <InputGroupContainer>
            <div>
              <InputLabel>Token</InputLabel>
              <Select
                normalPlaceholder='Token'
                onSelectItem={this.onSelectTokenSelect('toToken')}
                onChange={this.onChangeSearchToken('toToken')}
                value={this.state.toTokenSearchToken}
                options={
                  toWallet
                    ? toWallet.balances.map(b => ({
                      key: `${b.token.name}${b.token.symbol}${b.token.id}`,
                      value: <TokenSelect token={b.token} />,
                      ...b
                    }))
                    : []
                }
              />
              <BalanceTokenLabel>Balance: {this.getBalanceOfSelectedToken('toToken')}</BalanceTokenLabel>
            </div>
            <div>
              <InputLabel>Amount</InputLabel>
              <Input value={this.state.toTokenAmount} onChange={this.onChangeAmount('toToken')} type='amount' normalPlaceholder={'Token amount'} />
            </div>
          </InputGroupContainer>
        </div>
      </FromToContainer>
    )
  }
  render () {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <InnerTransferContainer>
          <h4>Transfer</h4>
          {this.renderFromSection()}
          {this.renderToSection()}

          {this.state.toTokenSelected && (
            <AllWalletsFetcher
              query={createSearchAddressQuery(this.state.exchangeAddress)}
              render={({ data }) => {
                return (
                  <div>
                    <InputLabel>Exchange Address</InputLabel>
                    <Select
                      normalPlaceholder='acc_0x000000000000000'
                      onSelectItem={this.onSelectExchangeAddressSelect}
                      value={this.state.exchangeAddress}
                      onChange={this.onChangeInputExchangeAddress}
                      options={data.map(d => {
                        return {
                          key: d.address,
                          value: <WalletSelect wallet={d} />,
                          ...d
                        }
                      })}
                    />
                  </div>
                )
              }}
            />
          )}
          <ButtonContainer>
            <Button size='small' type='submit' loading={this.state.submitting}>
              Transfer
            </Button>
          </ButtonContainer>
          <Error error={this.state.error}>{this.state.error}</Error>
        </InnerTransferContainer>
      </Form>
    )
  }
}
const EnhancedCreateTransaction = enhance(CreateTransaction)
export default class CreateTransactionModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    onCreateTransaction: PropTypes.func,
    fromAddress: PropTypes.string
  }
  render = () => {
    return (
      <Modal isOpen={this.props.open} onRequestClose={this.props.onRequestClose} contentLabel='create transaction modal' overlayClassName='dummy2'>
        <EnhancedCreateTransaction
          onRequestClose={this.props.onRequestClose}
          onCreateTransaction={this.props.onCreateTransaction}
          fromAddress={this.props.fromAddress}
        />
      </Modal>
    )
  }
}
