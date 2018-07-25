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
import { formatAmount } from '../utils/formatter'

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
    right: 15px;
    top: 15px;
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
const Error = styled.div`
  color: ${props => props.theme.colors.R400};
  text-align: center;
  padding: 10px 0;
  overflow: hidden;
  max-height: ${props => (props.error ? '100px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
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
  state = { amount: null, error: null }
  onChangeAmount = e => {
    this.setState({ amount: e.target.value })
  }
  onSubmit = async e => {
    e.preventDefault()
    this.setState({ submitStatus: 'SUBMITTED' })
    try {
      const result = await this.props.mintToken({
        id: this.props.token.id,
        amount: formatAmount(this.state.amount, this.props.token.subunit_to_unit)
      })
      if (result.data) {
        this.props.onRequestClose()
        this.setState({ submitStatus: 'SUCCESS', amount: null })
      } else {
        this.setState({ submitStatus: 'FAILED', error: result.error.description })
      }
    } catch (error) {
      this.setState({ submitStatus: 'FAILED' })
    }
  }
  onRequestClose = e => {
    this.props.onRequestClose()
    this.setState({ amount: null, error: null })
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
            step='any'
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
          <Error error={this.state.error}>{this.state.error}</Error>
        </MintTokenModalContainer>
      </Modal>
    )
  }
}

export default enhance(MintTokenModal)
