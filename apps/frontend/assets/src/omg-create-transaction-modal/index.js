import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'

import { Button, Icon, SelectInput } from '../omg-uikit'
import Modal from '../omg-modal'
import { transfer } from '../omg-transaction/action'
import { getWalletById } from '../omg-wallet/action'
import { formatReceiveAmountToTotal, formatAmount } from '../utils/formatter'
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
  }
  h4 {
    text-align: center;
    margin-bottom: 40px;
    font-size: 18px;
  }
`
const ButtonContainer = styled.div`
  text-align: center;
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
    border-radius: 2px;
  }
`
const InnerTransferContainer = styled.div`
  max-width: 600px;
  padding: 50px;
  margin: 0 auto;
`
const StyledSelectInput = styled(SelectInput)`
  margin-top: 10px;
  margin-bottom: 20px;
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
    onCreateTransaction: PropTypes.func,
    transfer: PropTypes.func
  }
  static defaultProps = {
    onCreateTransaction: _.noop
  }
  state = {
    fromTokenAmount: '',
    toTokenAmount: '',
    fromAddress: this.props.fromAddress || '',
    toAddress: ''
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
    this.setState({
      [`${type}SearchToken`]: _.get(token, 'token.name'),
      [`${type}Selected`]: token
    })
  }
  onSelectToAddressSelect = item => {
    if (item) {
      this.setState({
        toAddress: item.key,
        toAddressSelect: true,
        toTokenSelected: this.state.toTokenSelected
          ? item.balances.find(b => b.token.id === _.get(this.state.toTokenSelected, 'token.id'))
          : null
      })
    } else {
      this.setState({
        toAddress: '',
        toAddressSelect: false,
        toTokenSelected: null,
        toTokenSearchToken: ''
      })
    }
  }
  onSelectFromAddressSelect = item => {
    if (item) {
      this.setState({
        fromAddress: item.key,
        fromAddressSelect: true,
        fromTokenSelected: this.state.fromTokenSelected
          ? item.balances.find(b => b.token.id === _.get(this.state.fromTokenSelected, 'token.id'))
          : null
      })
    } else {
      this.setState({
        fromAddress: '',
        fromAddressSelect: false,
        fromTokenSelected: null,
        fromTokenSearchToken: ''
      })
    }
  }
  onSelectExchangeAddressSelect = item => {
    if (item) {
      this.setState({
        exchangeAddress: item.key,
        exchangeAddressSelect: true
      })
    } else {
      this.setState({
        exchangeAddress: '',
        exchangeAddressSelect: false
      })
    }
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const fromAmount = formatAmount(
        this.state.fromTokenAmount,
        _.get(this.state.fromTokenSelected, 'token.subunit_to_unit')
      )
      const toAmount = formatAmount(
        this.state.toTokenAmount,
        _.get(this.state.toTokenSelected, 'token.subunit_to_unit')
      )
      const result = await this.props.transfer({
        fromAddress: this.state.fromAddress.trim(),
        toAddress: this.state.toAddress.trim(),
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
      ? formatReceiveAmountToTotal(
        _.get(this.state[`${type}Selected`], 'amount'),
        _.get(this.state[`${type}Selected`], 'token.subunit_to_unit')
      )
      : '-'
  }

  renderFromSection () {
    const fromWallet = this.props.selectWalletById(this.state.fromAddress.trim())
    return (
      <FromToContainer>
        <h5>From</h5>
        <AllWalletsFetcher
          accountId={this.props.match.params.accountId}
          owned={false}
          query={createSearchAddressQuery(this.state.fromAddress)}
          shouldFetch={!!this.props.match.params.accountId || (fromWallet && !!fromWallet.account_id)}
          render={({ data }) => {
            return (
              <StyledSelectInput
                selectProps={{
                  label: 'Wallet Address',
                  clearable: true,
                  disabled: !!this.props.fromAddress,
                  onSelectItem: this.onSelectFromAddressSelect,
                  value: this.state.fromAddress,
                  onChange: this.onChangeInputFromAddress,
                  valueRenderer: this.state.fromAddressSelect
                    ? value => {
                      const wallet = _.find(data, i => i.address === value)
                      return wallet
                        ? <WalletSelect wallet={wallet} />
                        : value
                    }
                    : null,
                  options:
                    data
                      ? data.filter(w => w.identifier !== 'burn')
                        .map(d => {
                          return {
                            key: d.address,
                            value: <WalletSelect wallet={d} />,
                            ...d
                          }
                        })
                      : []
                }}
              />
            )
          }}
        />

        <StyledSelectInput
          inputProps={{
            label: 'Amount to send',
            value: this.state.fromTokenAmount,
            onChange: this.onChangeAmount('fromToken'),
            type: 'amount',
            maxAmountLength: 18,
            suffix: _.get(this.state.fromTokenSelected, 'token.symbol')
          }}
          selectProps={{
            label: 'Token',
            clearable: true,
            onSelectItem: this.onSelectTokenSelect('fromToken'),
            onChange: this.onChangeSearchToken('fromToken'),
            value: this.state.fromTokenSearchToken,
            filterByKey: true,
            valueRenderer: this.state.fromTokenSelected
              ? value => {
                const found = _.find(
                  fromWallet.balances,
                  b => b.token.name.toLowerCase() === value.toLowerCase()
                )
                return found
                  ? <TokenSelect balance={found.amount} token={found.token} />
                  : value
              }
              : null,
            options:
              fromWallet
                ? fromWallet.balances.map(b => ({
                  key: `${b.token.name}${b.token.symbol}${b.token.id}`,
                  value: <TokenSelect balance={b.amount} token={b.token} />,
                  ...b
                }))
                : []
          }}
        />
      </FromToContainer>
    )
  }
  renderToSection () {
    const toWallet = this.props.selectWalletById(this.state.toAddress.trim())
    return (
      <FromToContainer>
        <h5 style={{ marginTop: '20px' }}>To</h5>
        <AllWalletsFetcher
          query={createSearchAddressQuery(this.state.toAddress)}
          render={({ data }) => {
            return (
              <StyledSelectInput
                selectProps={{
                  label: 'Wallet Address',
                  clearable: true,
                  onSelectItem: this.onSelectToAddressSelect,
                  value: this.state.toAddress,
                  onChange: this.onChangeInputToAddress,
                  valueRenderer: this.state.toAddressSelect
                    ? value => {
                      const wallet = _.find(data, i => i.address === value)
                      return wallet
                        ? <WalletSelect wallet={wallet} />
                        : value
                    }
                    : null,
                  options:
                    data
                      ? data.map(d => {
                        return {
                          key: d.address,
                          value: <WalletSelect wallet={d} />,
                          ...d
                        }
                      })
                      : []
                }}
              />
            )
          }}
        />
        <div>
          <OptionalExplanation>
            The fields below are optional and should only be used if you want to perform an
            exchange. Leave the amount blank to let the server use the default exchange rate.
          </OptionalExplanation>

          <StyledSelectInput
            inputProps={{
              label: 'Amount',
              value: this.state.toTokenAmount,
              onChange: this.onChangeAmount('toToken'),
              type: 'amount',
              maxAmountLength: 18,
              suffix: _.get(this.state.toTokenSelected, 'token.symbol')
            }}
            selectProps={{
              label: 'Token',
              clearable: true,
              onSelectItem: this.onSelectTokenSelect('toToken'),
              onChange: this.onChangeSearchToken('toToken'),
              value: this.state.toTokenSearchToken,
              filterByKey: true,
              valueRenderer: this.state.toTokenSelected
                ? value => {
                  const found = _.find(
                    toWallet.balances,
                    b => b.token.name.toLowerCase() === value.toLowerCase()
                  )
                  return found
                    ? <TokenSelect balance={found.amount} token={found.token} />
                    : value
                }
                : null,
              options:
                toWallet
                  ? toWallet.balances.map(b => ({
                    key: `${b.token.name}${b.token.symbol}${b.token.id}`,
                    value: <TokenSelect balance={b.amount} token={b.token} />,
                    ...b
                  }))
                  : []
            }}
          />
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
                  <StyledSelectInput
                    selectProps={{
                      label: 'Exchange Address',
                      clearable: true,
                      onSelectItem: this.onSelectExchangeAddressSelect,
                      value: this.state.exchangeAddress,
                      onChange: this.onChangeInputExchangeAddress,
                      valueRenderer: this.state.exchangeAddressSelect
                        ? value => {
                          const wallet = _.find(data, i => i.address === value)
                          return wallet
                            ? <WalletSelect wallet={wallet} />
                            : value
                        }
                        : null,
                      options:
                        data
                          ? data.map(d => {
                            return {
                              key: d.address,
                              value: <WalletSelect wallet={d} />,
                              ...d
                            }
                          })
                          : []
                    }}
                  />
                )
              }}
            />
          )}
          <ButtonContainer>
            <Button size='small' type='submit' loading={this.state.submitting}>
              <span>Transfer</span>
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
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='create transaction modal'
        overlayClassName='dummy2'
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
