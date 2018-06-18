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
  width: 350px;
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

class CreateTransactionModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    wallet: PropTypes.object
  }
  state = {
    amount: '',
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
        amount: Number(this.state.amount * this.state.selectedToken.token.subunit_to_unit)
      })
      if (result.data.success) {
        this.props.onRequestClose()
        this.setState({ submitting: false, name: '', symbol: '', amount: 0, decimal: 18 })
      } else {
        this.setState({ submitting: false, error: result.data.data.description })
      }
    } catch (error) {
      this.setState({ submitting: false, error })
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
          <InputLabel>From</InputLabel>
          <Input
            normalPlaceholder='acc_0x000000000000000'
            value={this.props.wallet.address}
            disabled
          />
          <InputLabel>To Address</InputLabel>
          <Input
            normalPlaceholder='acc_0x000000000000000'
            value={this.state.toAddress}
            onChange={this.onChangeInputToAddress}
          />
          <InputLabel>Token</InputLabel>
          <Select
            normalPlaceholder='Token'
            onSelect={this.onSelect}
            options={this.props.wallet.balances.map(b => ({
              ...{
                key: b.token.id,
                value: `${b.token.name} (${b.token.symbol})`
              },
              ...b
            }))}
          />
          <BalanceTokenLabel>Balance: {this.state.selectedToken ? this.state.selectedToken.amount / _.get(this.state.selectedToken, 'token.subunit_to_unit') : '-'} </BalanceTokenLabel>
          <InputLabel>Amount</InputLabel>
          <Input
            value={this.state.amount}
            onChange={this.onChangeAmount}
            type='number'
          />
          <ButtonContainer>
            <Button size='small' type='submit' loading={this.state.submitting}>
              Transfer
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
  { createTransaction }
)(CreateTransactionModal)
