import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import web3Utils from 'web3-utils'

import { Button, Icon, SelectInput, Checkbox } from '../omg-uikit'
import Modal from '../omg-modal'
import { transfer } from '../omg-transaction/action'
import { getWalletById } from '../omg-wallet/action'
import { formatAmount } from '../utils/formatter'
import { AllBlockchainWalletsFetcher, BlockchainWalletBalanceFetcher } from '../omg-blockchain-wallet/blockchainwalletsFetcher'
import TokenSelect from '../omg-token-select'
import WalletSelect from '../omg-wallet-select'

const CheckboxGroup = styled.div`
  display: flex;
  flex-direction: column;
`
const LoadingCheckboxGroup = styled(CheckboxGroup)`
  color: ${props => props.theme.colors.S300};
`
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
const FromToContainer = styled.div`
  h5 {
    letter-spacing: 1px;
    background-color: ${props => props.theme.colors.S300};
    display: inline-block;
    padding: 5px 10px;
    border-radius: 2px;
  }
  i[name='Wallet'] {
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
    margin-right: 10px;
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
const StyledInput = styled(StyledSelectInput)`
`
const ChainSelect = styled.div`
  background-color: ${props => props.theme.colors.S100};
  border-radius: 6px;
  padding: 20px;
`

class CreateTransaction extends Component {
  static propTypes = {
    onRequestClose: PropTypes.func,
    wallet: PropTypes.object,
    getWalletById: PropTypes.func,
    onCreateTransaction: PropTypes.func,
    transfer: PropTypes.func
  }
  static defaultProps = {
    onCreateTransaction: _.noop
  }
  state = {
    fromTokenAmount: '',
    fromTokenSearchToken: '',
    wallet: this.props.wallet,
    toAddress: '',
    onEthereum: true
  }
  onChangeAmount = type => e => {
    this.setState({ [`${type}Amount`]: e.target.value })
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
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const fromAmount = formatAmount(
        this.state.fromTokenAmount,
        _.get(this.state.fromTokenSelected, 'token.subunit_to_unit')
      )
      const result = await this.props.transfer({
        onPlasma: !this.state.onEthereum,
        fromAddress: this.props.wallet.address,
        toAddress: this.state.toAddress.trim(),
        fromTokenId: _.get(this.state.fromTokenSelected, 'token.id'),
        toTokenId:
          _.get(this.state.toTokenSelected, 'token.id') ||
          _.get(this.state.fromTokenSelected, 'token.id'),
        amount: fromAmount
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

  renderFromSection () {
    const walletBalance = _.get(this.props, 'wallet.balances', [])
    return (
      <FromToContainer>
        <h5>From</h5>
        <StyledSelectInput
          selectProps={{
            label: 'Wallet Address',
            disabled: !!this.props.wallet,
            value: _.get(this.props, 'wallet.address'),
            valueRenderer: value => <WalletSelect wallet={this.props.wallet} />
          }}
        />
        <StyledSelectInput
          inputProps={{
            label: 'Amount to send',
            value: this.state.fromTokenAmount,
            onChange: this.onChangeAmount('fromToken'),
            type: 'amount',
            maxAmountLength: 18,
            suffix: _.get(this.state.fromTokenSelected, 'amount')
              ? _.get(this.state.fromTokenSelected, 'token.symbol')
              : null,
            disabled: !this.state.fromTokenSelected || this.state.fromTokenSelected.amount === 0
          }}
          selectProps={{
            label: 'Token',
            clearable: true,
            onSelectItem: this.onSelectTokenSelect('fromToken'),
            value: this.state.fromTokenSearchToken,
            filterByKey: true,
            valueRenderer: this.state.fromTokenSelected
              ? value => {
                const found = _.find(
                  walletBalance,
                  b => b.token.name.toLowerCase() === value.toLowerCase()
                )
                return found
                  ? <TokenSelect balance={found.amount} token={found.token} />
                  : value
              }
              : null,
            options:
              walletBalance.length
                ? walletBalance
                  .filter(b => b.token.blockchain_status === 'confirmed')
                  .map(b => ({
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
  onChangeInputToAddress = e => {
    this.setState({ toAddress: e.target.value })
  }
  renderToSection () {
    return (
      <FromToContainer>
        <h5 style={{ marginTop: '20px' }}>To</h5>
        <AllBlockchainWalletsFetcher
          render={({ blockchainWallets }) => {
            return (
              <StyledInput
                inputProps={{
                  label: 'External Blockchain Address',
                  clearable: true,
                  value: this.state.toAddress,
                  onChange: this.onChangeInputToAddress
                }}
              />
            )
          }}
        />
      </FromToContainer>
    )
  }
  renderPlasmaLoadingState = () => {
    return (
      <LoadingCheckboxGroup>
        <Checkbox
          key='Ethereum'
          label='Transfer on Ethereum'
          checked={false}
        />
        <Checkbox
          key='Plasma'
          label='Transfer on Plasma'
          checked={false}
        />
      </LoadingCheckboxGroup>
    )
  }

  renderChainSelect = () => {
    return (
      <ChainSelect>
        <AllBlockchainWalletsFetcher
          render={({ blockchainWallets, individualLoadingStatus }) => {
            const { address } = _.find(blockchainWallets, i => i.type === 'hot')
            if (individualLoadingStatus !== 'SUCCESS') {
              return this.renderPlasmaLoadingState()
            }
            return (
              <BlockchainWalletBalanceFetcher
                query={{ address }}
                render={({ data, individualLoadingStatus }) => {
                  if (individualLoadingStatus !== 'SUCCESS') {
                    return this.renderPlasmaLoadingState()
                  }
                  const tokenBalances = _.find(data, i => i.token.id === this.state.fromTokenSelected.token.id)
                  const { plasmaAmount } = tokenBalances

                  const internalAmount = this.state.fromTokenSelected.amount
                  const onPlasma = plasmaAmount > internalAmount

                  return (
                    <CheckboxGroup>
                      <Checkbox
                        key='Ethereum'
                        label='Transfer on Ethereum'
                        onClick={() => this.setState({ onEthereum: true })}
                        checked={this.state.onEthereum}
                      />
                      {onPlasma && (
                        <Checkbox
                          key='Plasma'
                          label='Transfer on Plasma'
                          onClick={() => this.setState({ onEthereum: false })}
                          checked={!this.state.onEthereum}
                        />
                      )}
                    </CheckboxGroup>
                  )
                }}
              />
            )
          }}
        />
      </ChainSelect>
    )
  }
  render () {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <InnerTransferContainer>
          <h4>External Transfer</h4>
          {this.renderFromSection()}
          {!!_.get(this.state.fromTokenSelected, 'amount') && this.renderChainSelect()}
          {this.renderToSection()}
          <ButtonContainer>
            <Button
              size='small'
              type='submit'
              disabled={
                !this.state.toAddress ||
                !web3Utils.isAddress(this.state.toAddress) ||
                !this.state.fromTokenSearchToken ||
                !this.state.fromTokenAmount
              }
              loading={this.state.submitting}
            >
              <span>Transfer</span>
            </Button>
          </ButtonContainer>
          <Error error={this.state.error}>{this.state.error}</Error>
        </InnerTransferContainer>
      </Form>
    )
  }
}
const enhance = compose(
  withRouter,
  connect(
    null,
    { transfer, getWalletById }
  )
)
const EnhancedCreateTransaction = enhance(CreateTransaction)
export default class InternalToExternalModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    onCreateTransaction: PropTypes.func,
    wallet: PropTypes.object
  }
  render = () => {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='internal to external modal'
        overlayClassName='internal-to-external-modal'
      >
        <EnhancedCreateTransaction
          onRequestClose={this.props.onRequestClose}
          onCreateTransaction={this.props.onCreateTransaction}
          wallet={this.props.wallet}
        />
      </Modal>
    )
  }
}
