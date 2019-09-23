import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'

import { Button, Icon, SelectInput } from '../omg-uikit'
import Modal from '../omg-modal'
import { getWalletById } from '../omg-wallet/action'
import { formatAmount } from '../utils/formatter'
import BlockchainWalletSelect from '../omg-blockchain-wallet-select'
import { plasmaDeposit } from '../omg-blockchain-wallet/action'
import { selectBlockchainWalletBalance } from '../omg-blockchain-wallet/selector'
import TokenSelect from '../omg-token-select'

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

class PlasmaDeposit extends Component {
  static propTypes = {
    onRequestClose: PropTypes.func,
    fromAddress: PropTypes.string,
    selectBlockchainWalletBalance: PropTypes.func,
    getWalletById: PropTypes.func,
    plasmaDeposit: PropTypes.func,
    onDepositComplete: PropTypes.func
  }
  state = {
    fromTokenAmount: '',
    fromTokenSearchToken: '',
    fromAddress: this.props.fromAddress || ''
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
  onDeposit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const fromAmount = formatAmount(
        this.state.fromTokenAmount,
        _.get(this.state.fromTokenSelected, 'token.subunit_to_unit')
      )
      const result = await this.props.plasmaDeposit({
        address: this.state.fromAddress.trim(),
        amount: parseInt(fromAmount),
        tokenId: _.get(this.state.fromTokenSelected, 'token.id')
      })
      if (result.data) {
        this.props.getWalletById(this.state.fromAddress)
        if (this.props.onDepositComplete) {
          this.props.onDepositComplete()
        }
        this.onRequestClose()
      } else {
        this.setState({
          submitting: false,
          error: result.error.description || result.error.message
        })
      }
    } catch (e) {
      this.setState({ error: JSON.stringify(e.message) })
    }
  }
  onRequestClose = () => {
    this.props.onRequestClose()
    this.setState({ submitting: false })
  }

  renderFromSection () {
    const walletBalance = this.props.selectBlockchainWalletBalance(this.state.fromAddress)
    return (
      <FromToContainer>
        <h5>From</h5>
        <StyledSelectInput
          selectProps={{
            label: 'Wallet Address',
            disabled: !!this.props.fromAddress,
            value: this.state.fromAddress,
            valueRenderer: value => (
              <BlockchainWalletSelect
                icon='Wallet'
                topRow={value}
                bottomRow='Hot wallet'
              />
            ),
            prefix: <Icon name='Wallet' />
          }}
        />
        <StyledSelectInput
          inputProps={{
            label: 'Amount to deposit',
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
                ? walletBalance.map(b => ({
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
  render () {
    return (
      <Form onSubmit={this.onDeposit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <InnerTransferContainer>
          <h4>OmiseGO Network Deposit</h4>
          {this.renderFromSection()}
          <ButtonContainer>
            <Button
              size='small'
              type='submit'
              disabled={
                !this.state.fromAddress ||
                !this.state.fromTokenSearchToken ||
                !this.state.fromTokenAmount
              }
              loading={this.state.submitting}
            >
              <span>Deposit</span>
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
    state => ({ selectBlockchainWalletBalance: selectBlockchainWalletBalance(state) }),
    { plasmaDeposit, getWalletById }
  )
)
const EnhancedPlasmaDeposit = enhance(PlasmaDeposit)

export default class PlasmaDepositModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    fromAddress: PropTypes.string,
    onDepositComplete: PropTypes.func
  }
  render = () => {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='plasma deposit modal'
        overlayClassName='plasma-deposit-modal'
      >
        <EnhancedPlasmaDeposit
          onRequestClose={this.props.onRequestClose}
          fromAddress={this.props.fromAddress}
          onDepositComplete={this.props.onDepositComplete}
        />
      </Modal>
    )
  }
}
