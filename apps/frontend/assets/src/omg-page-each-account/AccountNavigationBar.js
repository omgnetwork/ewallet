import React, { Fragment } from 'react'
import PropTypes from 'prop-types'
import { NavLink, withRouter } from 'react-router-dom'
import styled from 'styled-components'
import { compose } from 'recompose'

import { Avatar } from '../omg-uikit'
import AccountProvider from '../omg-account/accountProvider'
import WalletDropdownChooser from './WalletDropdownChooser'

const LinksContainer = styled.div`
  display: flex;
  overflow: auto;
  margin-bottom: -1.5px;
  white-space: nowrap;
  &::-webkit-scrollbar {
    display: none;
  }
  .wallet-dropdown,
  a {
    cursor: pointer;
    padding: 0 10px;
    color: ${props => props.theme.colors.B100};
    div.account-link-text {
      transition: border-bottom 300ms ease-in-out;
      border-bottom: 2px solid transparent;
      padding: 30px 0;
    }
  }

  .wallet-dropdown div .navlink-active,
  a.navlink-active {
    color: ${props => props.theme.colors.B400};
    div.account-link-text {
      border-bottom: 2px solid ${props => props.theme.colors.S500};
    }
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
`
const AccountNameContainer = styled.div`
  display: flex;
  align-items: center;
  overflow: hidden;
  white-space: nowrap;
  flex: 1 1 200px;
  padding-right: 20px;
  > div:first-child {
    margin-right: 10px;
    flex: 0 0 auto;
  }
  h4 {
    text-overflow: ellipsis;
    overflow: hidden;
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
            <AccountNameContainer>
              {account && (
                <Fragment>
                  <Avatar image={_.get(account, 'avatar.small')} name={account.name} size={32} />{' '}
                  <h4>{account.email || account.name}</h4>
                </Fragment>
              )}
            </AccountNameContainer>
          )
        }}
      />
      <LinksContainer>
        <NavLink to={`/accounts/${accountId}/details`} activeClassName='navlink-active'>
          <div className='account-link-text'>Details</div>
        </NavLink>
        <div className='wallet-dropdown'>
          <WalletDropdownChooser {...props} />
        </div>
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
          to={`/accounts/${accountId}/keys`}
          activeClassName='navlink-active'
          className='account-link'
        >
          <div className='account-link-text'>Keys</div>
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
          <div className='account-link-text'>Edit</div>
        </NavLink>
      </LinksContainer>
    </AccountNavigationBarContainer>
  )
}

AccountNavigationBar.propTypes = {
  match: PropTypes.object
}

export default enhance(AccountNavigationBar)
