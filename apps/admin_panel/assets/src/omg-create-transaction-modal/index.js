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
import { formatRecieveAmountToTotal, formatAmount } from '../utils/formatter'
import WalletProvider from '../omg-wallet/walletProvider'
import AllWalletsFetcher from '../omg-wallet/allWalletsFetcher'
const Form = styled.form`
  padding: 50px;
  width: 400px;
  > i {
    position: absolute;
    right: 15px;
    top: 15px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  input {
    margin-top: 5px;
  }
  button {
    margin: 35px 0 0;
    font-size: 14px;
  }
  h4 {
    text-align: center;
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
  max-height: ${props => (props.error ? '50px' : 0)};
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
const enhance = compose(
  withRouter,
  connect(
    null,
    { transfer, getWalletById }
  )
)
class CreateTransaction extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    fromAddress: PropTypes.string,
    getWalletById: PropTypes.func,
    onCreateTransaction: PropTypes.func
  }
  static defaultProps = {
    onCreateTransaction: _.noop
  }
  state = {}
  componentWillReceiveProps = nextProps => {
    if (this.state.fromAddress !== nextProps.fromAddress && nextProps.fromAddress !== undefined) {
      this.setState({ fromAddress: nextProps.fromAddress })
    }
  }
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
    this.setState({ [`${type}SearchToken`]: token.value, [`${type}Selected`]: token })
  }
  onSelectToAddressSelect = item => {
    this.setState({ toAddress: item.key })
  }
  onSelectFromAddressSelect = item => {
    this.setState({ fromAddress: item.key })
  }
  onSelectExchangeAddressSelect = item => {
    this.setState({ exchangeAddress: item.key })
  }
  onFocusSelect = type => () => {
    this.setState({ [`${type}SearchToken`]: '', [`${type}Selected`]: null })
  }

  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const fromAmount =
        !this.state.fromTokenAmount || !this.state.fromTokenSelected
          ? null
          : formatAmount(
              this.state.fromTokenAmount,
              _.get(this.state.fromTokenSelected, 'token.subunit_to_unit')
            )
      const toAmount =
        !this.state.toTokenAmount || !this.state.toTokenSelected
          ? null
          : formatAmount(
              this.state.toTokenAmount,
              _.get(this.state.toTokenSelected, 'token.subunit_to_unit')
            )
      const result = await this.props.transfer({
        fromAddress: this.state.fromAddress,
        toAddress: this.state.toAddress,
        fromTokenId: _.get(this.state.fromTokenSelected, 'token.id'),
        toTokenId:
          _.get(this.state.toTokenSelected, 'token.id') ||
          _.get(this.state.fromTokenSelected, 'token.id'),
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
      ? formatRecieveAmountToTotal(
          _.get(this.state[`${type}Selected`], 'amount'),
          _.get(this.state[`${type}Selected`], 'token.subunit_to_unit')
        )
      : '-'
  }
  render () {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4>Transfer</h4>
        <InputLabel>From Address</InputLabel>
        <AllWalletsFetcher
          query={{ search: this.state.fromAddress }}
          render={({ data }) => {
            return (
              <Select
                normalPlaceholder='acc_0x000000000000000'
                onSelectItem={this.onSelectFromAddressSelect}
                value={this.state.fromAddress}
                onChange={this.onChangeInputFromAddress}
                options={data.map(d => {
                  return {
                    key: d.address,
                    value: `${d.address} ( ${_.get(d, 'account.name') ||
                      _.get(d, 'user.username') ||
                      _.get(d, 'user.email')} )`
                  }
                })}
              />
            )
          }}
        />
        <WalletProvider
          walletAddress={this.state.fromAddress}
          render={({ wallet }) => {
            return (
              <InputGroupContainer>
                <div>
                  <InputLabel>Token</InputLabel>
                  <Select
                    normalPlaceholder='Token'
                    onSelectItem={this.onSelectTokenSelect('fromToken')}
                    onChange={this.onChangeSearchToken('fromToken')}
                    value={this.state.fromTokenSearchToken}
                    onFocus={this.onFocusSelect('fromToken')}
                    options={
                      wallet
                        ? wallet.balances.map(b => ({
                          ...{
                            key: b.token.id,
                            value: `${b.token.name} (${b.token.symbol})`
                          },
                          ...b
                        }))
                        : []
                    }
                  />
                  <BalanceTokenLabel>
                    Balance: {this.getBalanceOfSelectedToken('fromToken')}
                  </BalanceTokenLabel>
                </div>
                <div>
                  <InputLabel>Amount</InputLabel>
                  <Input
                    value={this.state.fromAddressAmount}
                    onChange={this.onChangeAmount('fromToken')}
                    type='number'
                  />
                </div>
              </InputGroupContainer>
            )
          }}
        />
        <InputLabel>To Address</InputLabel>
        <AllWalletsFetcher
          query={{ search: this.state.toAddress }}
          render={({ data }) => {
            return (
              <Select
                normalPlaceholder='acc_0x000000000000000'
                onSelectItem={this.onSelectToAddressSelect}
                value={this.state.toAddress}
                onChange={this.onChangeInputToAddress}
                options={data.map(d => {
                  return {
                    key: d.address,
                    value: `${d.address} ( ${_.get(d, 'account.name') ||
                      _.get(d, 'user.username') ||
                      _.get(d, 'user.email')} )`
                  }
                })}
              />
            )
          }}
        />
        <WalletProvider
          walletAddress={this.state.toAddress}
          render={({ wallet }) => {
            return (
              <InputGroupContainer>
                <div>
                  <InputLabel>Token</InputLabel>
                  <Select
                    normalPlaceholder='Token'
                    onSelectItem={this.onSelectTokenSelect('toToken')}
                    onChange={this.onChangeSearchToken('toToken')}
                    value={this.state.toTokenSearchToken}
                    onFocus={this.onFocusSelect('toToken')}
                    options={
                      wallet
                        ? wallet.balances.map(b => ({
                          ...{
                            key: b.token.id,
                            value: `${b.token.name} (${b.token.symbol})`
                          },
                          ...b
                        }))
                        : []
                    }
                  />
                  <BalanceTokenLabel>
                    Balance: {this.getBalanceOfSelectedToken('toToken')}
                  </BalanceTokenLabel>
                </div>
                <div>
                  <InputLabel>Amount</InputLabel>
                  <Input
                    value={this.state.toAddressAmount}
                    onChange={this.onChangeAmount('toToken')}
                    type='number'
                  />
                </div>
              </InputGroupContainer>
            )
          }}
        />
        {this.state.toTokenSelected && (
          <AllWalletsFetcher
            query={{ search: this.state.exchangeAddress }}
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
                        value: `${d.address} ( ${_.get(d, 'account.name') ||
                          _.get(d, 'user.username') ||
                          _.get(d, 'user.email')} )`
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
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='create account modal'
      >
        <EnhancedCreateTransaction
          onRequestClose={this.props.onRequestClose}
          onCreateTransaction={this.props.onCreateTransaction}
          fromAddress={this.props.fromAddress}
        />
      </Modal>
    )
  }
}
