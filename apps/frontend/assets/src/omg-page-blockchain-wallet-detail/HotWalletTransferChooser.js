import React, { Component } from 'react'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { compose } from 'recompose'

import PopperRenderer from '../omg-popper'
import { openModal } from '../omg-modal/action'
import withDropdownState from '../omg-uikit/dropdown/withDropdownState'
import { Icon, Button } from '../omg-uikit'
import { DropdownBox } from '../omg-uikit/dropdown'

const DropdownItem = styled.div`
  padding: 7px 10px;
  padding-right: 20px;
  font-size: 12px;
  color: ${props => props.theme.colors.B100};
  cursor: pointer;
  i,
  span {
    vertical-align: middle;
    display: inline-block;
  }
  :hover {
    color: ${props => props.theme.colors.B400};
  }
  i {
    margin-right: 5px;
  }
`
const ButtonStyle = styled(Button)`
  margin-left: 10px;
  i {
    margin-left: 10px;
    margin-right: 0 !important;
  }
`
class HotWalletTransferChooser extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onClickButton: PropTypes.func,
    onDepositComplete: PropTypes.func,
    openModal: PropTypes.func,
    fromAddress: PropTypes.string
  }
  renderDropdown = () => {
    return (
      <DropdownBox>
        <DropdownItem
          key='transfer'
          onClick={() => {
            this.props.openModal({
              id: 'hotWalletTransferModal',
              fromAddress: this.props.fromAddress
            })
          }}
        >
          <Icon name='Transaction' />
          <span>Transfer to Cold Wallet</span>
        </DropdownItem>
        <DropdownItem
          key='plasma-deposit'
          onClick={() => this.props.openModal({
            id: 'plasmaDepositModal',
            fromAddress: this.props.fromAddress,
            onDepositComplete: this.props.onDepositComplete
          })}
        >
          <Icon name='Download' />
          <span>OmiseGO Network Deposit</span>
        </DropdownItem>
      </DropdownBox>
    )
  }
  renderButton = () => {
    return (
      <ButtonStyle
        key='hot-wallet-transfer-chooser'
        size='small'
        styleType='primary'
        onClick={this.props.onClickButton}
      >
        <span>Transfer</span>
        {this.props.open
          ? <Icon name='Chevron-Up' />
          : <Icon name='Chevron-Down' />
        }
      </ButtonStyle>
    )
  }
  render () {
    return (
      <PopperRenderer
        offset='0px, 5px'
        modifiers={{ flip: { enabled: false } }}
        renderReference={this.renderButton}
        open={this.props.open}
        renderPopper={this.renderDropdown}
      />
    )
  }
}

const enhance = compose(
  withDropdownState,
  connect(
    null,
    { openModal }
  )
)

export default enhance(HotWalletTransferChooser)
