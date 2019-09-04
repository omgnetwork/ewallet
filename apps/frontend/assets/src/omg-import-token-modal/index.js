import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { connect } from 'react-redux'

import { Input, Button, Icon } from '../omg-uikit'
import Modal from '../omg-modal'
import { getErc20Capabilities, createToken } from '../omg-token/action'
import { formatAmount } from '../utils/formatter'

const Form = styled.form`
  padding: 50px;
  width: 250px;
  > i {
    position: absolute;
    right: 15px;
    top: 15px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  input {
    margin-top: 50px;
  }
  button {
    margin: 35px 0 0;
    font-size: 14px;
  }
  h4 {
    text-align: center;
  }
`
const AddressStepStyle = styled(Form)``
const ButtonContainer = styled.div`
  text-align: center;
  button:first-child {
    margin-right: 10px;
  }
  button:last-child {
    margin-right: 0px;
  }
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

class ImportToken extends Component {
  static propTypes = {
    createToken: PropTypes.func,
    getErc20Capabilities: PropTypes.func,
    onFetchSuccess: PropTypes.func,
    onRequestClose: PropTypes.func
  }
  state = {
    importedToken: null,
    error: '',
    submitting: false,
    step: 1,
    name: '',
    symbol: '',
    amount: '',
    decimal: 18,
    blockchainAddress: ''
  }
  onChangeInputName = e => {
    this.setState({ name: e.target.value })
  }
  onChangeInputSymbol = e => {
    this.setState({ symbol: e.target.value })
  }
  onChangeAmount = e => {
    this.setState({ amount: e.target.value })
  }
  onChangeDecimal = e => {
    this.setState({ decimal: e.target.value })
  }
  shouldSubmit () {
    return this.state.decimal <= 18 && this.state.name && this.state.symbol
  }
  checkErc20 = async e => {
    e.preventDefault()
    try {
      this.setState({ submitting: true })
      const result = await this.props.getErc20Capabilities(this.state.blockchainAddress)
      if (result.data) {
        this.setState({
          importedToken: result.data,
          submitting: false,
          error: null,
          step: 2,
          name: result.data.name,
          symbol: result.data.symbol,
          amount: result.data.total_supply,
          decimal: result.data.decimals
        })
      } else {
        this.setState({
          submitting: false,
          error: result.error.description || result.error.message
        })
      }
    } catch (e) {
      this.setState({ submitting: false })
    }
  }
  onSubmit = async e => {
    e.preventDefault()
    if (this.shouldSubmit()) {
      try {
        this.setState({ submitting: true })
        const result = await this.props.createToken({
          name: this.state.name,
          symbol: this.state.symbol,
          amount: formatAmount(this.state.amount, 10 ** this.state.decimal),
          decimal: this.state.decimal
        })
        if (result.data) {
          this.props.onRequestClose()
          this.props.onFetchSuccess()
        } else {
          this.setState({
            submitting: false,
            error: result.error.description || result.error.message
          })
        }
      } catch (e) {
        this.setState({ submitting: false })
      }
    }
  }
  goBack = e => {
    e.preventDefault()
    this.setState({
      importedToken: null,
      submitting: false,
      error: null,
      step: 1,
      name: '',
      symbol: '',
      amount: '',
      decimal: '',
      blockchainAddress: ''
    })
  }
  renderCreationStep = () => {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4>Import Token</h4>
        <Input
          disabled={!!this.state.importedToken.name}
          placeholder='Token name'
          autofocus
          value={this.state.name}
          onChange={this.onChangeInputName}
        />
        <Input
          disabled={!!this.state.importedToken.symbol}
          placeholder='Token symbol'
          value={this.state.symbol}
          onChange={this.onChangeInputSymbol}
        />
        <Input
          disabled={!!this.state.importedToken.decimals}
          placeholder='Decimal point'
          value={this.state.decimal}
          onChange={this.onChangeDecimal}
          error={this.state.decimal > 18}
          errorText={'Decimal point should not exceed 18'}
          type='number'
          step={'1'}
        />
        <Input
          disabled={!!this.state.importedToken.total_supply}
          placeholder='Amount (Optional)'
          value={this.state.amount}
          onChange={this.onChangeAmount}
          type='amount'
        />
        <ButtonContainer>
          <Button
            size='small'
            styleType='secondary'
            disabled={this.state.submitting}
            onClick={this.goBack}
          >
            <span>Back</span>
          </Button>
          <Button
            size='small'
            type='submit'
            loading={this.state.submitting}
            disabled={!this.shouldSubmit() || this.state.submitting}
          >
            <span>Import Token</span>
          </Button>
        </ButtonContainer>
        <Error error={this.state.error}>{this.state.error}</Error>
      </Form>
    )
  }
  renderAddressStep = () => {
    return (
      <AddressStepStyle>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4>Import Token</h4>
        <Input
          autofocus
          placeholder='ERC20 Address'
          value={this.state.blockchainAddress}
          onChange={e => this.setState({ blockchainAddress: e.target.value })}
        />
        <ButtonContainer>
          <Button
            size='small'
            loading={false}
            disabled={!this.state.blockchainAddress}
            onClick={this.checkErc20}
          >
            <span>Next</span>
          </Button>
        </ButtonContainer>
        <Error error={this.state.error}>{this.state.error}</Error>
      </AddressStepStyle>
    )
  }
  render () {
    switch (this.state.step) {
      case 1:
        return this.renderAddressStep()
      case 2:
        return this.renderCreationStep()
      default:
        return null
    }
  }
}

class ImportTokenModal extends Component {
  static propTypes = {
    onRequestClose: PropTypes.func,
    open: PropTypes.bool,
    createToken: PropTypes.func,
    getErc20Capabilities: PropTypes.func,
    onFetchSuccess: PropTypes.func
  }
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='import token modal'
      >
        <ImportToken
          onRequestClose={this.props.onRequestClose}
          createToken={this.props.createToken}
          getErc20Capabilities={this.props.getErc20Capabilities}
          onFetchSuccess={this.props.onFetchSuccess}
        />
      </Modal>
    )
  }
}
export default connect(
  null,
  { createToken, getErc20Capabilities }
)(ImportTokenModal)
