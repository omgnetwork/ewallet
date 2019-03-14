import React from 'react'
import PropTypes from 'prop-types'
import { NavLink, withRouter } from 'react-router-dom'
import { Avatar } from '../omg-uikit'
import AccountProvider from '../omg-account/accountProvider'
import styled from 'styled-components'
import WalletDropdownChooser from './WalletDropdownChooser'
import { compose } from 'recompose'
const LinksContainer = styled.div`
  display: flex;
  margin-bottom: -1.5px;
  a {
    display: block;
    padding: 0 10px;
    color: ${props => props.theme.colors.S500};
    div.account-link-text {
      border-bottom: 2px solid transparent;
      padding: 30px 0;
    }
  }
  a.navlink-active {
    color: ${props => props.theme.colors.B400};
    div.account-link-text {
      border-bottom: 2px solid ${props => props.theme.colors.S500};
    }
  }
  @media screen and (max-width: 1200px) {
    width: calc(100% - 200px);
    overflow: auto;
    white-space: nowrap;
  }
`
const AccountNavigationBarContainer = styled.div`
  display: flex;
  justify-content: flex-end;
  align-items: center;
  border-bottom: 1px solid ${props => props.theme.colors.S300};
  margin-left: -8%;
  margin-right: -8%;
  padding-right: 8%;
  padding-left: 8%;
  > div {
    flex: 1 1 auto;
  }
  ${LinksContainer} {
    flex: 0 0 auto;
  }
`
const AccountNameContainer = styled.div`
  display: flex;
  align-items: center;
  > div:first-child {
    margin-right: 10px;
  }
`

const enhance = compose(withRouter)

function AccountNavigationBar (props) {
  const accountId = props.match.params.accountId
  return (
    <AccountNavigationBarContainer>
      <AccountProvider
        accountId={accountId}
        render={({ account }) => {
          return (
            <div>
              {account && (
                <AccountNameContainer>
                  <Avatar image={_.get(account, 'avatar.small')} name={account.name} size={32} />{' '}
                  <h4>{account.email || account.name}</h4>
                </AccountNameContainer>
              )}
            </div>
          )
        }}
      />
      <LinksContainer>
        <NavLink to={`/accounts/${accountId}/detail`} activeClassName='navlink-active'>
          <div className='account-link-text'>Details</div>
        </NavLink>
        <WalletDropdownChooser {...props} />
        <NavLink
          to={`/accounts/${accountId}/transactions`}
          activeClassName='navlink-active'
          className='account-link'
        >
          <div className='account-link-text'>Transactions</div>
        </NavLink>
        <NavLink
          to={`/accounts/${accountId}/requests`}
          activeClassName='navlink-active'
          className='account-link'
        >
          <div className='account-link-text'>Requests</div>
        </NavLink>
        <NavLink
          to={`/accounts/${accountId}/consumptions`}
          activeClassName='navlink-active'
          className='account-link'
        >
          <div className='account-link-text'>Consumptions</div>
        </NavLink>
        <NavLink
          to={`/accounts/${accountId}/users`}
          activeClassName='navlink-active'
          className='account-link'
        >
          <div className='account-link-text'>Users</div>
        </NavLink>
        <NavLink
          to={`/accounts/${accountId}/admins`}
          activeClassName='navlink-active'
          className='account-link'
        >
          <div className='account-link-text'>Admins</div>
        </NavLink>
        <NavLink
          to={`/accounts/${accountId}/activity`}
          activeClassName='navlink-active'
          className='account-link'
        >
          <div className='account-link-text'>Activities</div>
        </NavLink>
        <NavLink
          to={`/accounts/${accountId}/setting`}
          activeClassName='navlink-active'
          className='account-link'
        >
          <div className='account-link-text'>Setting</div>
        </NavLink>
      </LinksContainer>
    </AccountNavigationBarContainer>
  )
}

AccountNavigationBar.propTypes = {
  match: PropTypes.object
}

export default enhance(AccountNavigationBar)
