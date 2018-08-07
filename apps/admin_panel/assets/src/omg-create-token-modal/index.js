import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input, Button, Icon } from '../omg-uikit'
import Modal from '../omg-modal'
import { createToken } from '../omg-token/action'
import { connect } from 'react-redux'
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

class CreateToken extends Component {
  static propTypes = {
    createToken: PropTypes.func,
    onFetchSuccess: PropTypes.func,
    onRequestClose: PropTypes.func
  }
  state = {
    name: '',
    symbol: '',
    amount: null,
    decimal: 18
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
  render () {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Icon name='Close' onClick={this.props.onRequestClose} />
        <h4>Create Token</h4>
        <Input
          placeholder='Token name'
          autofocus
          value={this.state.name}
          onChange={this.onChangeInputName}
        />
        <Input
          placeholder='Token symbol'
          value={this.state.symbol}
          onChange={this.onChangeInputSymbol}
        />
        <Input
          placeholder='Decimal point'
          value={this.state.decimal}
          onChange={this.onChangeDecimal}
          error={this.state.decimal > 18}
          errorText={'Decimal point should not exceed 18'}
          type='number'
          step={'1'}
        />
        <Input
          placeholder='Amount (Optional)'
          value={this.state.amount}
          onChange={this.onChangeAmount}
          type='number'
          step='any'
        />
        <ButtonContainer>
          <Button
            size='small'
            type='submit'
            loading={this.state.submitting}
            disabled={!this.shouldSubmit()}
          >
            Create Token
          </Button>
        </ButtonContainer>
        <Error error={this.state.error}>{this.state.error}</Error>
      </Form>
    )
  }
}

class CreateTokenModal extends Component {
  static propTypes = {
    onRequestClose: PropTypes.func,
    open: PropTypes.bool,
    createToken: PropTypes.func,
    onFetchSuccess: PropTypes.func
  }
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        contentLabel='create token modal'
      >
        <CreateToken
          onRequestClose={this.props.onRequestClose}
          createToken={this.props.createToken}
          onFetchSuccess={this.props.onFetchSuccess}
        />
      </Modal>
    )
  }
}
export default connect(
  null,
  { createToken }
)(CreateTokenModal)
