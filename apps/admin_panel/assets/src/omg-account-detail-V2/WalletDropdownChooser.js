import React, { Component } from 'react'
import PropTypes from 'prop-types'
import PopperRenderer from '../omg-popper'
import withDropdownState from '../omg-uikit/dropdown/withDropdownState'
import { Icon } from '../omg-uikit'
import { DropdownBox } from '../omg-uikit/dropdown'
import styled from 'styled-components'
import { compose } from 'recompose'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
const DropdownItem = styled.div`
  padding: 7px 10px;
  padding-right: 20px;
  font-size: 12px;
  color: ${props => props.theme.colors.B100};
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

const enhance = compose(
  withRouter,
  withDropdownState
)
class WalletDropdown extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onClickButton: PropTypes.func,
    history: PropTypes.object,
    match: PropTypes.object,
    location: PropTypes.object
  }
  state = {}
  onClickFilterWallet = type => e => {
    this.setState({ type })
    this.props.history.push(
      `/accounts/${this.props.match.params.accountId}/wallets/?walletType=${type}`
    )
  }
  onClickCurrentWallet = e => {
    const { walletType } = queryString.parse(this.props.location.search)
    this.props.history.push(
      `/accounts/${this.props.match.params.accountId}/wallets/?walletType=${this.state.type ||
        walletType ||
        'all'}`
    )
  }
  renderWalletDropdown = () => {
    return (
      <DropdownBox>
        <DropdownItem onClick={this.onClickFilterWallet('all')}>
          <Icon name='Wallet' /> <span>All Wallets</span>
        </DropdownItem>
        <DropdownItem onClick={this.onClickFilterWallet('account')}>
          <Icon name='Wallet' /> <span>Account Wallets</span>
        </DropdownItem>
        <DropdownItem onClick={this.onClickFilterWallet('user')}>
          <Icon name='Wallet' />
          <span>Users Wallets</span>
        </DropdownItem>
      </DropdownBox>
    )
  }
  render () {
    const nameMap = {
      all: 'All Wallets',
      account: 'Account Wallets',
      user: 'User Wallets'
    }
    const { walletType } = queryString.parse(this.props.location.search)
    return (
      <PopperRenderer
        offset='50px, -25px'
        modifiers={{
          flip: {
            enabled: false
          }
        }}
        renderReference={() => (
          <div>
            <span onClick={this.onClickCurrentWallet}>
              {nameMap[this.state.type || walletType] || nameMap.all}
            </span>{' '}
            {this.props.open ? (
              <Icon name='Chevron-Up' onClick={this.props.onClickButton} />
            ) : (
              <Icon name='Chevron-Down' onClick={this.props.onClickButton} />
            )}
          </div>
        )}
        open={this.props.open}
        renderPopper={this.renderWalletDropdown}
      />
    )
  }
}

export default enhance(WalletDropdown)
