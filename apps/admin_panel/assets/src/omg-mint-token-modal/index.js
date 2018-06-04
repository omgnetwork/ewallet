import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Modal from 'react-modal'
import { Button, Input, Icon } from '../omg-uikit'
import { mintToken } from '../omg-token/action'
import { connect } from 'react-redux'
const customStyles = {
  content: {
    top: '50%',
    left: '50%',
    right: 'auto',
    bottom: 'auto',
    marginRight: '-50%',
    transform: 'translate(-50%, -50%)',
    border: 'none'
  },
  overlay: {
    backgroundColor: 'rgba(0,0,0,0.5)'
  }
}
const MintTokenModalContainer = styled.form`
  position: relative;
  width: 350px;
  padding: 30px;
  h4 {
    margin-bottom: 50px;
    text-align: center;
  }
  > i {
    position: absolute;
    right: 0;
    top: 0;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
`
const ButtonsContainer = styled.div`
  padding-top: 25px;
  margin-top: 20px;
  text-align: center;
  button {
    :not(:last-child) {
      margin-right: 15px;
    }
  }
`
class MintTokenModal extends PureComponent {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    token: PropTypes.string,
    mintToken: PropTypes.func.isRequired
  }
  state = { amount: 0 }
  onChangeAmount = e => {
    this.setState({ amount: e.target.value })
  }
  onSubmit = async e => {
    e.preventDefault()
    const result = await this.props.mintToken({
      id: this.props.token.id,
      amount: this.state.amount
    })
    if (result.data.success) {
      this.props.onRequestClose()
    }
  }
  onRequestClose = e => {
    this.props.onRequestClose()
    this.setState({ amount: 0 })
  }
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.onRequestClose}
        style={customStyles}
        contentLabel='mint token modal'
      >
        <MintTokenModalContainer onSubmit={this.onSubmit}>
          <Icon name='Close' onClick={this.onRequestClose} />
          <h4>Mint {this.props.token.name}</h4>
          <Input
            placeholder='Amount'
            type='number'
            value={this.state.amount}
            autofocus
            onChange={this.onChangeAmount}
          />
          <ButtonsContainer>
            <Button styleType='primary' size='small' type='submit'>
              Mint
            </Button>
          </ButtonsContainer>
        </MintTokenModalContainer>
      </Modal>
    )
  }
}

export default connect(null, { mintToken })(MintTokenModal)
