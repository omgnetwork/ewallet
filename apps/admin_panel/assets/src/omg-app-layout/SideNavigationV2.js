import React, { PureComponent } from 'react'
import styled from 'styled-components'
import { Icon, LoadingSkeleton } from '../omg-uikit'
import { Link } from 'react-router-dom'
import { withRouter } from 'react-router'
import PropTypes from 'prop-types'
import CurrentUserProvider from '../omg-user-current/currentUserProvider'
import { fuzzySearch } from '../utils/search'
import ProfileDropdown from './ProfileDropdown'
import { selectRecentAccounts } from '../omg-recent-account/selector'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import FlipMove from 'react-flip-move'
const SideNavigationContainer = styled.div`
  background-color: #f0f2f5;
  height: 100%;
  overflow: auto;
`
const NavigationItem = styled.div`
  padding: 5px 35px;
  white-space: nowrap;
  text-align: left;
  font-size: 14px;
  color: ${props => (props.active ? props.theme.colors.BL400 : 'inherit')};
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
    color: ${props => props.theme.colors.BL400};
  }
`
const RecentAccountItem = styled(NavigationItem)`
  color: ${props => (props.active ? props.theme.colors.BL400 : props.theme.colors.S500)};
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
const RecentAccount = styled.div`
  margin-left: 32px;
`

const enhance = compose(
  withRouter,
  connect(
    state => ({ recentAccounts: selectRecentAccounts(state) }),
    null
  )
)

class SideNavigation extends PureComponent {
  static propTypes = {
    location: PropTypes.object,
    className: PropTypes.string,
    recentAccounts: PropTypes.array,
    match: PropTypes.object
  }
  static defaultProps = {
    recentAccounts: []
  }
  constructor (props) {
    super(props)
    this.dataLink = [
      {
        icon: 'Token',
        to: '/tokens',
        text: 'Tokens'
      },
      {
        icon: 'Key',
        to: '/keys',
        text: 'Keys'
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
        {loadingStatus === 'SUCCESS' ? <ProfileDropdown /> : <LoadingSkeleton height='18px' />}
      </CurrentAccountContainer>
    )
  }

  renderRecentAccounts () {
    return this.props.recentAccounts.length ? (
      <FlipMove>
        {this.props.recentAccounts.map((account, i) => {
          return (
            <div key={account.id || i}>
              <Link to={`/accounts/${account.id}/detail`}>
                <RecentAccountItem active={this.props.match.params.accountId === account.id}>
                  <RecentAccount className='recent-account'>{account.name}</RecentAccount>
                </RecentAccountItem>
              </Link>
            </div>
          )
        })}
      </FlipMove>
    ) : null
  }
  renderOverview () {
    const firstSubPath = this.props.location.pathname.split('/')[1]
    return this.overviewLinks.map(link => {
      return (
        <Link to={link.to} key={link.to}>
          <NavigationItem active={fuzzySearch(link.to, `/${firstSubPath}`)}>
            <Icon name={link.icon} /> <span>{link.text}</span>
          </NavigationItem>
        </Link>
      )
    })
  }

  render () {
    const firstSubPath = this.props.location.pathname.split('/')[1]
    const matchedAccountId = this.props.match.params.accountId
    return (
      <SideNavigationContainer className={this.props.className}>
        <NavigationItemsContainer>
          <CurrentUserProvider render={this.renderCurrentUser} />
          <MenuName> MANAGE </MenuName>
          <Link to={'/accounts'}>
            <NavigationItem
              active={!matchedAccountId && fuzzySearch('/accounts', `/${firstSubPath}`)}
            >
              <Icon name='Merchant' /> <span>{'Accounts'}</span>
            </NavigationItem>
          </Link>
          {this.renderRecentAccounts()}
          {this.dataLink.map(link => {
            return (
              <Link to={link.to} key={link.to}>
                <NavigationItem active={fuzzySearch(link.to, `/${firstSubPath}`)}>
                  <Icon name={link.icon} /> <span>{link.text}</span>
                </NavigationItem>
              </Link>
            )
          })}
          <MenuName> OVERVIEW </MenuName>
          {this.renderOverview()}
        </NavigationItemsContainer>
      </SideNavigationContainer>
    )
  }
}

export default enhance(SideNavigation)
