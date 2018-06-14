import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input, Button, Icon, Select } from '../omg-uikit'
import Modal from 'react-modal'
import { createTransaction } from '../omg-transaction/action'
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

class CreateTransactionModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    wallet: PropTypes.object
  }
  state = {
    amount: '',
    selectedToken: {},
    toAddress: ''
  }
  onChangeInputToAddress = e => {
    this.setState({ toAddress: e.target.value })
  }
  onChangeAmount = e => {
    this.setState({ amount: e.target.value })
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitting: true })

    try {
      const result = await this.props.createTransaction({
        fromAddress: this.props.wallet.address,
        toAddress: this.state.toAddress,
        tokenId: this.state.selectedToken.token.id,
        amount: this.state.amount
      })
      if (result.data.success) {
        this.props.onRequestClose()
        this.setState({ submitting: false, name: '', symbol: '', amount: 0, decimal: 18 })
      } else {
        this.setState({ submitting: false })
      }
    } catch (errror) {
      this.setState({ submitting: false })
    }
  }
  onSelect = item => {
    this.setState({ selectedToken: item })
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
          <h4>Transfer Token</h4>
          <InputLabel>To Address</InputLabel>
          <Input
            normalPlaceholder='acc_01cfda0qygekaqgxc7qsvwc83h'
            value={this.state.toAddress}
            onChange={this.onChangeInputToAddress}
          />
          <InputLabel>Token</InputLabel>
          <Select
            normalPlaceholder='OMG'
            onSelect={this.onSelect}
            options={this.props.wallet.balances.map(b => ({
              ...{
                key: b.token.id,
                value: `${b.token.name} (${b.token.symbol})`
              },
              ...b
            }))}
          />
          <BalanceTokenLabel>Balance: {this.state.selectedToken.amount} </BalanceTokenLabel>
          <InputLabel>Amount</InputLabel>
          <Input
            normalPlaceholder='1,000,000'
            value={this.state.amount}
            onChange={this.onChangeAmount}
            type='number'
          />
          <ButtonContainer>
            <Button size='small' type='submit' loading={this.state.submitting}>
              Transfer
            </Button>
          </ButtonContainer>
          <div>{this.state.error}</div>
        </Form>
      </Modal>
    )
  }
}

export default connect(
  null,
  { createTransaction }
)(CreateTransactionModal)
