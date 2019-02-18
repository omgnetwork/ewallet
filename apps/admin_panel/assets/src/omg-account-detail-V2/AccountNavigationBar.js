import React from 'react'
import PropTypes from 'prop-types'
import { NavLink, withRouter } from 'react-router-dom'
import { Avatar } from '../omg-uikit'
import { useAccount } from '../omg-account/accountProvider'
import styled from 'styled-components'
import WalletDropdownChooser from './WalletDropdownChooser'
const LinksContainer = styled.div`
  display: flex;
  margin-bottom: -1.5px;
  > a {
    display: block;
    padding: 0 10px;
    > div:first-child {
      border-bottom: 2px solid transparent;
      padding: 30px 0;
    }
  }
  .navlink-active {
    > div {
      border-bottom: 2px solid ${props => props.theme.colors.B100};
    }
  }
`
const AccountNavigationBarContainer = styled.div`
  display: flex;
  justify-content: flex-end;
  align-items: center;
  border-bottom: 1px solid ${props => props.theme.colors.S300};
  > div {
    flex: 1 1 auto;
  }
  ${LinksContainer} {
    flex: 0 0 auto;
  }
`
// REACT HOOK EXPERIMENT
function AccountNavigationBar (props) {
  const { account, loadingStatus } = useAccount(props.match.params.accountId)
  return (
    <AccountNavigationBarContainer>
      <div>{loadingStatus === 'SUCCESS' && <Avatar name={account.name} />}</div>
      <LinksContainer>
        <NavLink
          to={`/accounts/${props.match.params.accountId}/detail`}
          activeClassName='navlink-active'
        >
          <div>Details</div>
        </NavLink>
        <NavLink
          to={`/accounts/${props.match.params.accountId}/wallets`}
          activeClassName='navlink-active'
        >
          <WalletDropdownChooser />
        </NavLink>
        <NavLink
          to={`/accounts/${props.match.params.accountId}/transactions`}
          activeClassName='navlink-active'
        >
          <div>Transactions</div>
        </NavLink>
        <NavLink
          to={`/accounts/${props.match.params.accountId}/requests`}
          activeClassName='navlink-active'
        >
          <div>Requests</div>
        </NavLink>
        <NavLink
          to={`/accounts/${props.match.params.accountId}/consumptions`}
          activeClassName='navlink-active'
        >
          <div>Consumptions</div>
        </NavLink>
        <NavLink
          to={`/accounts/${props.match.params.accountId}/users`}
          activeClassName='navlink-active'
        >
          <div>Users</div>
        </NavLink>
        <NavLink
          to={`/accounts/${props.match.params.accountId}/admins`}
          activeClassName='navlink-active'
        >
          <div>Admins</div>
        </NavLink>
        <NavLink
          to={`/accounts/${props.match.params.accountId}/setting`}
          activeClassName='navlink-active'
        >
          <div>Setting</div>
        </NavLink>
      </LinksContainer>
    </AccountNavigationBarContainer>
  )
}

AccountNavigationBar.propTypes = {
  match: PropTypes.object,
  location: PropTypes.object
}

export default withRouter(AccountNavigationBar)
