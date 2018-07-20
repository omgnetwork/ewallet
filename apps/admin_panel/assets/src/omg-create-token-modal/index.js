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
  max-height: ${props => (props.error ? '50px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
`

class CreateTokenModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    createToken: PropTypes.func,
    onFetchSuccess: PropTypes.func
  }
  initialState = {
    name: '',
    symbol: '',
    amount: null,
    decimal: 18,
    error: '',
    submitting: false
  }
  state = this.initialState
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
  onRequestClose = () => {
    this.setState(this.initialState)
    this.props.onRequestClose()
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    try {
      const result = await this.props.createToken({
        name: this.state.name,
        symbol: this.state.symbol,
        amount: formatAmount(this.state.amount, 10 ** this.state.decimal),
        decimal: this.state.decimal
      })
      if (result.data) {
        this.onRequestClose()
        this.props.onFetchSuccess()
      } else {
        this.setState({
          submitting: false,
          error: result.error.description || result.error.message
        })
      }
    } catch (e) {
      this.setState({ submitting: false, error: e })
    }
  }
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.onRequestClose}
        contentLabel='create account modal'
      >
        <Form onSubmit={this.onSubmit} noValidate>
          <Icon name='Close' onClick={this.onRequestClose} />
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
          />
          <Input
            placeholder='Amount (Optional)'
            value={this.state.amount}
            onChange={this.onChangeAmount}
            type='number'
          />
          <ButtonContainer>
            <Button size='small' type='submit' loading={this.state.submitting}>
              Create Token
            </Button>
          </ButtonContainer>
          <Error error={this.state.error}>{this.state.error}</Error>
        </Form>
      </Modal>
    )
  }
}

export default connect(
  null,
  { createToken }
)(CreateTokenModal)
