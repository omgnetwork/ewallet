import React, { PureComponent } from 'react'
import styled, {keyframes} from 'styled-components'
import { Icon } from '../omg-uikit'
import { Link } from 'react-router-dom'
import { withRouter } from 'react-router'
import PropTypes from 'prop-types'
import CurrentAccountProvider from '../omg-account-current/currentAccountProvider'
const SideNavigationContainer = styled.div`
  max-width: 230px;
  background-color: ${props => props.theme.colors.B300};
  height: 100%;
  color: white;
  padding: 35px 0;
`
const NavigationItem = styled.div`
  padding: 15px 30px;
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
    background-color: #30343F;
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
  height: 120px;
  width: 120px;
  border-radius: 50%;
  background-color: ${props => props.theme.colors.B200};
  margin: 0 auto;
  position: relative;
  color: white;
  background-image: url(${props => props.backgroundImage});
  background-size: cover;
  background-position: center;
`
const LoadingLogo = Logo.extend`
  background-color: ${props => props.theme.colors.B200};
  background-image: ${props => `linear-gradient(90deg, ${props.theme.colors.B200}, grey, ${props.theme.colors.B200})`};
  background-size: 200px 100%;
  background-repeat: no-repeat;
  animation: ${progress} 1.5s ease-in-out infinite;
`
const NavigationItemsContainer = styled.div`
  margin-top: 20px;
  text-align: center;
`
const SwitchAccount = styled.div`
  padding: 10px 10px;
  display: inline-block;
  text-align: center;
  font-weight: 300;
  border: 1px solid ${props => props.theme.colors.B100};
  letter-spacing: 1px;
  white-space: nowrap;
  margin-bottom: 25px;
  color: ${props => props.theme.colors.B100};
  cursor: pointer;
  background-color: ${props => (props.active ? props.theme.colors.B400 : 'transparent')};
  span {
    vertical-align: middle;
    margin-right: 10px;
  }
  :hover {
    background-color: ${props => props.theme.colors.B400};
  }
`
class SideNavigation extends PureComponent {
  static propTypes = {
    location: PropTypes.object,
    className: PropTypes.string,
    onClickSwitchAccount: PropTypes.func,
    switchAccount: PropTypes.bool
  }
  constructor (props) {
    super(props)
    this.dataLink = [
      { icon: 'Dashboard', to: '/dashboard', text: 'DASHBOARD' },
      { icon: 'Merchant', to: '/accounts', text: 'ACCOUNT' },
      { icon: 'Token', to: '/token', text: 'TOKEN' },
      { icon: 'Wallet', to: '/wallets', text: 'WALLET' },
      { icon: 'Transaction', to: '/transaction', text: 'TRANSACTION' },
      { icon: 'Key', to: '/api', text: 'API' },
      { icon: 'People', to: '/users', text: 'USERS' },
      { icon: 'Setting', to: '/setting', text: 'SETTING' }
    ]
  }
  renderCurrentAccount = ({ currentAccount, loadingStatus }) => {
    return (
      loadingStatus === 'SUCCESS'
      ? (
        <Logo backgroundImage={_.get(currentAccount, 'avatar.large')}>
          {/* <CurrentAccountDummy>
            {currentAccount.name}
          </CurrentAccountDummy> */}
        </Logo>
      )
      : <LoadingLogo />
    )
  }

  render () {
    const accountIdFromLocation = this.props.location.pathname.split('/')[1]
    return (
      <SideNavigationContainer className={this.props.className}>
        <CurrentAccountProvider render={this.renderCurrentAccount} />
        <NavigationItemsContainer>
          <SwitchAccount
            active={this.props.switchAccount}
            onClick={this.props.onClickSwitchAccount}
          >
            <span>Switch Account</span> <Icon name='Chevron-Right' />
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
