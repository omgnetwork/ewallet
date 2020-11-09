import React, { Fragment } from 'react'
import { Link, RouteComponentProps } from 'react-router-dom'
import { withRouter } from 'react-router'
import { useDispatch, useSelector } from 'react-redux'
import FlipMove from 'react-flip-move'
import styled from 'styled-components'

import { Icon } from 'omg-uikit'
import { fuzzySearch } from 'utils/search'
import { selectRecentAccounts } from 'omg-recent-account/selector'
import { logout } from 'omg-session/action'
import { selectInternalEnabled } from 'omg-configuration/selector'
import theme from 'adminPanelApp/theme'


const SideNavigationContainer = styled.div`
  background-color: ${theme.colors.S200};
  height: 100%;
  overflow: auto;
`
const NavigationItem = styled.div<{ active: boolean }>`
  padding: 5px 35px;
  white-space: nowrap;
  text-align: left;
  font-size: 14px;
  color: ${({active}) => (active ? theme.colors.BL400 : 'inherit')};
  transition: 0.1s background-color;
  > * {
    overflow: hidden;
    text-overflow: ellipsis;
  }
  span {
    vertical-align: middle;
  }
  i {
    margin-right: 15px;
    font-size: 14px;
    color: ${theme.colors.S500};
    font-weight: 400;
  }
  :hover {
    cursor: pointer;
    color: ${theme.colors.BL400};
  }
`
const RecentAccountItem = styled(NavigationItem)`
  color: ${(props) =>
    props.active ? theme.colors.BL400 : theme.colors.S500};
`

const NavigationItemsContainer = styled.div`
  margin-top: 20px;
  a {
    color: inherit;
  }
`

const MenuName = styled.div`
  padding: 5px 35px;
  margin-top: 30px;
  font-size: 10px;
  color: ${theme.colors.B100};
  font-weight: 600;
  letter-spacing: 1px;
`
const RecentAccount = styled.div`
  margin-left: 32px;
`

const OverviewContainer = styled.div`
  padding-bottom: 30px;
  border-bottom: 1px solid ${theme.colors.S300};
`

interface SideNavigationProps extends RouteComponentProps<{accountId: string}> {
  className: string,
}

const SideNavigation = ({ className, history, location, match }: SideNavigationProps) => {
  const internalEnabled: boolean = useSelector(selectInternalEnabled())
  const recentAccounts: {[key:string]: any}[] = useSelector(selectRecentAccounts())
  const dispatch = useDispatch()

  const onLogout = async (e) => {
    dispatch(logout())
    history.push('/login')
  }

  const manageLinks = [
    {
      icon: 'Token',
      to: '/tokens',
      text: 'Tokens'
    },
    {
      icon: 'People',
      to: '/admins',
      text: 'Admins'
    },
    {
      icon: 'Key',
      to: '/keys',
      text: 'Keys'
    },
    {
      icon: 'Setting',
      to: '/configuration/global_settings',
      text: 'Configuration'
    }
  ]

  const overviewLinks = [
    internalEnabled? {
      icon: 'Wallet',
      to: '/wallets',
      text: 'Wallets'
    } : null,
    {
      icon: 'Wallet',
      to: '/blockchain_wallets',
      text: 'Blockchain Wallets'
    },
    {
      icon: 'Transaction',
      to: '/transaction',
      text: 'Transactions'
    },
    internalEnabled? {
      icon: 'Request',
      to: '/requests',
      text: 'Requests'
    } : null,
    internalEnabled? {
      icon: 'Consumption',
      to: '/consumptions',
      text: 'Consumptions'
    } : null,
    {
      icon: 'People',
      to: '/users',
      text: 'Users'
    },
    {
      icon: 'History',
      to: '/activity',
      text: 'Activity Logs'
    }
  ]


  const renderRecentAccounts = () => {
    return recentAccounts.length ? (
      <FlipMove>
        {recentAccounts.map((account, i) => {
          return (
            <div key={account.id || i}>
              <Link to={`/accounts/${account.id}/details`}>
                <RecentAccountItem
                  active={match.params.accountId === account.id}
                >
                  <RecentAccount className="recent-account">
                    {account.name}
                  </RecentAccount>
                </RecentAccountItem>
              </Link>
            </div>
          )
        })}
      </FlipMove>
    ) : null
  }

  const renderOverview = () => {
    const firstSubPath = location.pathname.split('/')[1]
    return (
      <OverviewContainer>
        <MenuName> OVERVIEW </MenuName>
        {overviewLinks.map((link) => {
          return link? (
            <Link to={link.to} key={link.to}>
              <NavigationItem active={link.to.includes(`/${firstSubPath}`)}>
                <Icon name={link.icon} />
                <span>{link.text}</span>
              </NavigationItem>
            </Link>
          ): null
        })}
      </OverviewContainer>
    )
  }

  const renderManage = () => {
    const matchedAccountId = match.params.accountId
    const firstSubPath = location.pathname.split('/')[1]
    return (
      <Fragment>
        <MenuName> MANAGE </MenuName>
        <Link to={'/accounts'}>
          <NavigationItem
            active={
              !matchedAccountId && fuzzySearch('/accounts', `/${firstSubPath}`)
            }
          >
            <Icon name="Merchant" />
            <span>{'Accounts'}</span>
          </NavigationItem>
        </Link>
        {renderRecentAccounts()}
        {manageLinks.map((link) => {
          return (
            <Link to={link.to} key={link.to}>
              <NavigationItem active={link.to.includes(`/${firstSubPath}`)}>
                <Icon name={link.icon} />
                <span>{link.text}</span>
              </NavigationItem>
            </Link>
          )
        })}
      </Fragment>
    )
  }
  const renderMyProfile = () => {
    const firstSubPath = location.pathname.split('/')[1]
    return (
      <Fragment>
        <MenuName> MY PROFILE </MenuName>
        <Link to={'/user_setting'}>
          <NavigationItem
            active={fuzzySearch('/user_setting', `/${firstSubPath}`)}
          >
            <Icon name={'Profile'} />
            <span>My Profile</span>
          </NavigationItem>
        </Link>
        <NavigationItem active={true} onClick={onLogout}>
          <Icon name={'Arrow-Left'} />
          <span>Log Out</span>
        </NavigationItem>
      </Fragment>
    )
  }

  return (
    <SideNavigationContainer className={className}>
      <NavigationItemsContainer>
        {renderManage()}
        {renderOverview()}
        {renderMyProfile()}
      </NavigationItemsContainer>
    </SideNavigationContainer>
  )
}

export default withRouter(SideNavigation)
