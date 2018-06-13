import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input, Button, Icon, Select } from '../omg-uikit'
import Modal from 'react-modal'
import { createToken } from '../omg-token/action'
import { connect } from 'react-redux'
const customStyles = {
  content: {
    top: '50%',
    left: '50%',
    right: 'auto',
    bottom: 'auto',
    marginRight: '-50%',
    transform: 'translate(-50%, -50%)',
    border: 'none',
    padding: 0,
    overflow: 'hidden'
  },
  overlay: {
    backgroundColor: 'rgba(0,0,0,0.5)'
  }
}
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

class CreateTokenModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    createToken: PropTypes.func
  }
  state = {
    name: '',
    symbol: '',
    amount: 0,
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
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })
    const result = await this.props.createToken({
      name: this.state.name,
      symbol: this.state.symbol,
      amount: this.state.amount,
      decimal: this.state.decimal
    })
    if (result.data.success) {
      this.props.onRequestClose()
      this.setState({ submitting: false, name: '', symbol: '', amount: 0, decimal: 18 })
    }
  }
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        style={customStyles}
        onRequestClose={this.props.onRequestClose}
        contentLabel='create account modal'
      >
        <Form onSubmit={this.onSubmit} noValidate>
          <Icon name='Close' onClick={this.props.onRequestClose} />
          <h4>Create Token</h4>
          <Select />
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
          <div>{this.state.error}</div>
        </Form>
      </Modal>
    )
  }
}

export default connect(null, { createToken })(CreateTokenModal)
