import React, { PureComponent } from 'react'
import styled from 'styled-components'
import { Icon, LoadingSkeleton } from '../omg-uikit'
import { Link } from 'react-router-dom'
import { withRouter } from 'react-router'
import PropTypes from 'prop-types'
import CurrentUserProvider from '../omg-user-current/currentUserProvider'
import { fuzzySearch } from '../utils/search'
import ProfileDropdown from './ProfileDropdown'
const SideNavigationContainer = styled.div`
  background-color: #f0f2f5;
  height: 100%;
  padding: 25px 0;
  overflow: auto;
`
const NavigationItem = styled.div`
  padding: 5px 35px;
  white-space: nowrap;
  text-align: left;
  font-size: 14px;
  background-color: ${props => (props.active ? props.theme.colors.S300 : 'transparent')};
  transition: 0.1s background-color;
  span {
    vertical-align: middle;
  }
  i {
    margin-right: 15px;
    font-size: 14px;
    color: ${props => props.theme.colors.S500};
    font-weight: 400;
  }
  :hover {
    background-color: ${props => props.theme.colors.S300};
  }
`

const NavigationItemsContainer = styled.div`
  margin-top: 20px;
  a {
    color: inherit;
  }
`
const CurrentAccountContainer = styled.div`
  text-align: left;
  display: flex;
  align-items: center;
  padding: 0 35px;
  height: 30px;
`

const MenuName = styled.div`
  padding: 5px 35px;
  margin-top: 30px;
  font-size: 10px;
  color: ${props => props.theme.colors.B100};
  font-weight: 600;
  letter-spacing: 1px;
`
class SideNavigation extends PureComponent {
  static propTypes = {
    location: PropTypes.object,
    className: PropTypes.string,
    onClickSwitchAccount: PropTypes.func,
    switchAccount: PropTypes.bool,
    match: PropTypes.object
  }
  constructor (props) {
    super(props)
    this.dataLink = [
      {
        icon: 'Merchant',
        to: '/accounts',
        text: 'Accounts'
      },
      {
        icon: 'Token',
        to: '/tokens',
        text: 'Tokens'
      },
      {
        icon: 'Key',
        to: '/api',
        text: 'Api Keys'
      },
      {
        icon: 'People',
        to: '/admins',
        text: 'Admins'
      },
      {
        icon: 'Setting',
        to: '/configuration',
        text: 'Configurations'
      }
    ]
    this.overviewLinks = [
      {
        icon: 'Wallet',
        to: '/wallets',
        text: 'Wallets'
      },
      {
        icon: 'Transaction',
        to: '/transaction',
        text: 'Transactions'
      },
      {
        icon: 'Request',
        to: '/requests',
        text: 'Requests'
      },
      {
        icon: 'Consumption',
        to: '/consumptions',
        text: 'Consumptions'
      },
      {
        icon: 'People',
        to: '/users',
        text: 'Users'
      },
      {
        icon: 'Setting',
        to: '/activity',
        text: 'Activity Logs'
      }
    ]
  }

  renderCurrentUser = ({ currentUser, loadingStatus }) => {
    return (
      <CurrentAccountContainer>
        {loadingStatus === 'SUCCESS' ? (
          <ProfileDropdown />
        ) : (
          <LoadingSkeleton height='18px' />
        )}
      </CurrentAccountContainer>
    )
  }

  render () {
    return (
      <SideNavigationContainer className={this.props.className}>
        <NavigationItemsContainer>
          <CurrentUserProvider render={this.renderCurrentUser} />
          <MenuName> MANAGE </MenuName>
          {this.dataLink.map(link => {
            return (
              <Link to={link.to} key={link.to}>
                <NavigationItem
                  active={fuzzySearch(link.to, `/${this.props.location.pathname.split('/')[1]}`)}
                >
                  <Icon name={link.icon} /> <span>{link.text}</span>
                </NavigationItem>
              </Link>
            )
          })}
          <MenuName> OVERVIEW </MenuName>
          {this.overviewLinks.map(link => {
            return (
              <Link to={link.to} key={link.to}>
                <NavigationItem
                  active={fuzzySearch(link.to, `/${this.props.location.pathname.split('/')[1]}`)}
                >
                  <Icon name={link.icon} /> <span>{link.text}</span>
                </NavigationItem>
              </Link>
            )
          })}
        </NavigationItemsContainer>
      </SideNavigationContainer>
    )
  }
}

export default withRouter(SideNavigation)
