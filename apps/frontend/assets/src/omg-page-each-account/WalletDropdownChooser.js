import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { compose } from 'recompose'
import { Link } from 'react-router-dom'

import PopperRenderer from '../omg-popper'
import withDropdownState from '../omg-uikit/dropdown/withDropdownState'
import { Icon } from '../omg-uikit'
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
const NavLinkContainer = styled.div`
  .account-link-text {
    display: inline-block;
    i {
      margin-left: 5px;
      font-size: 12px;
    }
  }
  a {
    display: inline;
  }
`

const enhance = compose(withDropdownState)
class WalletDropdown extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onClickButton: PropTypes.func,
    history: PropTypes.object,
    match: PropTypes.object,
    location: PropTypes.object
  }
  state = { walletType: 'account' }

  onClickFilterWallet = walletType => () => {
    this.setState({ walletType })
    this.props.history.push(
      `/accounts/${
        this.props.match.params.accountId
      }/wallets/?walletType=${walletType}`
    )
  }

  renderWalletDropdown = () => {
    return (
      <DropdownBox>
        <DropdownItem onClick={this.onClickFilterWallet('account')}>
          <Icon name='Wallet' />
          <span>Account Wallets</span>
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
      account: 'Account Wallets',
      user: 'User Wallets'
    }
    const activePage = this.props.location.pathname.includes('wallets')
    const { accountId } = this.props.match.params
    return (
      <PopperRenderer
        offset='0px, -25px'
        modifiers={{
          flip: {
            enabled: false
          }
        }}
        renderReference={() => (
          <NavLinkContainer className={activePage ? 'navlink-active' : ''}>
            <div className='account-link-text'>
              <Link
                to={`/accounts/${accountId}/wallets/?walletType=${
                  this.state.walletType
                }`}
              >
                {nameMap[this.state.walletType] || nameMap.account}
              </Link>
              {this.props.open ? (
                <Icon name='Chevron-Up' onClick={this.props.onClickButton} />
              ) : (
                <Icon name='Chevron-Down' onClick={this.props.onClickButton} />
              )}
            </div>
          </NavLinkContainer>
        )}
        open={this.props.open}
        renderPopper={this.renderWalletDropdown}
      />
    )
  }
}

export default enhance(WalletDropdown)
