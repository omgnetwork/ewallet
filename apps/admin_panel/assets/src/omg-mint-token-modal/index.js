import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Modal from '../omg-modal'
import { Button, Input, Icon } from '../omg-uikit'
import { mintToken } from '../omg-token/action'
import { getWalletsByAccountId } from '../omg-wallet/action'
import { connect } from 'react-redux'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'
import {formatAmount} from '../utils/formatter'

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

const enhance = compose(
  withRouter,
  connect(
    null,
    { mintToken, getWalletsByAccountId }
  )
)
class MintTokenModal extends PureComponent {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func,
    token: PropTypes.object,
    mintToken: PropTypes.func.isRequired,
    getWalletsByAccountId: PropTypes.func.isRequired,
    match: PropTypes.object
  }
  state = { amount: 0 }
  onChangeAmount = e => {
    this.setState({ amount: e.target.value })
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitStatus: 'SUBMITTED' })
    const result = await this.props.mintToken({
      id: this.props.token.id,
      amount: formatAmount(this.state.amount, this.props.token.subunit_to_unit)
    })
    if (result.data.success) {
      this.props.onRequestClose()
      this.setState({ submitStatus: 'SUCCESS', amount: 0 })
    } else {
      this.setState({ submitStatus: 'FAILED', amount: 0 })
    }
  }
  onRequestClose = e => {
    this.props.onRequestClose()
  }
  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.onRequestClose}
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
            <Button
              styleType='primary'
              size='small'
              type='submit'
              loading={this.state.submitStatus === 'SUBMITTED'}
            >
              Mint
            </Button>
          </ButtonsContainer>
        </MintTokenModalContainer>
      </Modal>
    )
  }
}

export default enhance(MintTokenModal)
