import React, { PureComponent } from 'react'
import styled, { keyframes } from 'styled-components'
import { Icon } from '../omg-uikit'
import { Link } from 'react-router-dom'
import { withRouter } from 'react-router'
import PropTypes from 'prop-types'
import CurrentAccountProvider from '../omg-account-current/currentAccountProvider'
const SideNavigationContainer = styled.div`
  background-color: ${props => props.theme.colors.B300};
  height: 100%;
  color: white;
  padding: 35px 0;
`
const NavigationItem = styled.div`
  padding: 15px 35px;
  white-space: nowrap;
  letter-spacing: 1px;
  font-weight: 600;
  text-align: left;
  font-size: 12px;
  background-color: ${props => (props.active ? '#30343F' : 'transparent')};
  transition: 0.1s background-color;
  span {
    vertical-align: middle;
  }
  i {
    margin-right: 15px;
    font-size: 14px;
  }
  :hover {
    background-color: #30343f;
  }
`
const progress = keyframes`
0% {
      background-position: -200px 0;
  }
  100% {
      background-position: calc(200px + 100%) 0;
  }
`
const Logo = styled.div`
  height: 36px;
  width: 36px;
  flex: 0 0 auto;
  vertical-align: middle;
  border-radius: 4px;
  background-color: ${props => props.theme.colors.B200};
  position: relative;
  color: white;
  background-image: url(${props => props.backgroundImage});
  background-size: cover;
  background-position: center;
`
const LoadingLogo = Logo.extend`
  background-color: ${props => props.theme.colors.B200};
  background-image: ${props =>
    `linear-gradient(90deg, ${props.theme.colors.B200}, grey, ${props.theme.colors.B200})`};
  background-size: 200px 100%;
  background-repeat: no-repeat;
  animation: ${progress} 1.5s ease-in-out infinite;
`
const NavigationItemsContainer = styled.div`
  margin-top: 20px;
  a {
    color: inherit;
  }
`
const SwitchAccountButton = styled.button`
  padding: 5px 15px;
  display: inline-block;
  font-weight: 300;
  border-radius: 4px;
  border: 1px solid;
  border-color: ${props => (props.active ? 'transparent' : props.theme.colors.B100)};
  letter-spacing: 1px;
  white-space: nowrap;
  color: ${props => props.theme.colors.B100};
  cursor: pointer;
  background-color: ${props => (props.active ? props.theme.colors.B400 : 'transparent')};
  span {
    display: inline-block;
    margin-bottom: 2px;
    vertical-align: middle;
  }
  :hover {
    background-color: ${props => props.theme.colors.B400};
  }
`
const SwitchAccount = styled.div`
  background-color: ${props => (props.active ? props.theme.colors.B400 : 'transparent')};
  margin-bottom: 25px;
  padding: 8px 35px;
  text-align: left;
  margin-top: 25px;
`
const CurrentAccountContainer = styled.div`
  text-align: left;
  display: flex;
  align-items: center;
  padding: 0 35px;
`
const CurrentAccountName = styled.h4`
  flex: 1 1 auto;
  margin-left: 15px;
  font-size: 14px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
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
      { icon: 'Dashboard', to: '/dashboard', text: 'DASHBOARD' },
      { icon: 'Merchant', to: '/accounts', text: 'ACCOUNT' },
      { icon: 'Token', to: '/token', text: 'TOKEN' },
      { icon: 'Wallet', to: '/wallets', text: 'WALLET' },
      { icon: 'Transaction', to: '/transaction', text: 'TRANSACTION' },
      { icon: 'Request', to: '/requests', text: 'REQUEST' },
      { icon: 'Consumption', to: '/consumptions', text: 'CONSUMPTION' },
      { icon: 'Key', to: '/api', text: 'API' },
      { icon: 'People', to: '/users', text: 'USERS' },
      { icon: 'Setting', to: '/setting', text: 'SETTING' }
    ]
  }
  renderCurrentAccount = ({ currentAccount, loadingStatus }) => {
    return (
      <CurrentAccountContainer>
        {loadingStatus === 'SUCCESS' ? (
          <Logo backgroundImage={_.get(currentAccount, 'avatar.large')} />
        ) : (
          <LoadingLogo />
        )}
        <CurrentAccountName>{_.get(currentAccount, 'name', '')}</CurrentAccountName>
      </CurrentAccountContainer>
    )
  }

  render () {
    const accountIdFromLocation = this.props.match.params.accountId
    return (
      <SideNavigationContainer className={this.props.className}>
        <NavigationItemsContainer>
          <CurrentAccountProvider render={this.renderCurrentAccount} />
          <SwitchAccount active={this.props.switchAccount}>
            <SwitchAccountButton
              active={this.props.switchAccount}
              onClick={this.props.onClickSwitchAccount}
            >
              <span>Switch Account</span> <Icon name='Chevron-Right' />
            </SwitchAccountButton>
          </SwitchAccount>
          {this.dataLink.map(link => {
            const reg = new RegExp(link.to)
            return (
              <Link to={`/${accountIdFromLocation}${link.to}`} key={link.to}>
                <NavigationItem active={reg.test(this.props.location.pathname)}>
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
