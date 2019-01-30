import React, { Component } from 'react'
import PropTypes from 'prop-types'
import TabsManager from '../omg-tabs'
import AccountProvider from '../omg-account/accountProvider'
import { withRouter, Link } from 'react-router-dom'
import DetailPage from '../omg-page-account-detail'
import WalletPage from '../omg-page-wallets'
import styled from 'styled-components'
import { Avatar } from '../omg-uikit'
const AccountTabDetailPageContainer = styled.div`
  a {
    color: inherit;
  }
  h2 {
    font-size: 24px;
    font-weight: 600;
  }
`

const AccountNameContainer = styled.div`
  display: flex;
  align-items: center;
`
const AccountName = styled.div`
  margin-left: 10px;
  font-weight: 600;
  font-size: 24px;
  margin-top: -5px;
`
class AccountTabsPage extends Component {
  static propTypes = {
    match: PropTypes.object
  }
  renderAccountTabPage = ({ account }) => {
    const tabs = { detail: 0, wallets: 1, requests: 2 }
    const activeIndex = tabs[this.props.match.params.tab]
    return account ? (
      <AccountTabDetailPageContainer>
        <AccountNameContainer>
          <Avatar image={account.avatar.small} />
          <AccountName>{account.name}</AccountName>
        </AccountNameContainer>
        <TabsManager
          activeIndex={activeIndex}
          tabs={[
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/detail`}>Details</Link>
              ),
              content: <DetailPage />
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/wallets`}>Wallets</Link>
              ),
              content: <WalletPage accountId={this.props.match.params.accountId} />
            },
            {
              title: 'Requests',
              content: null
            },
            {
              title: 'Consumption',
              content: null
            },
            {
              title: 'Transactions',
              content: null
            },
            {
              title: 'Users',
              content: null
            },
            {
              title: 'Team',
              content: null
            },
            {
              title: 'Setting',
              content: null
            }
          ]}
        />
      </AccountTabDetailPageContainer>
    ) : null
  }
  render () {
    return (
      <AccountProvider
        render={this.renderAccountTabPage}
        accountId={this.props.match.params.accountId}
        {...this.props}
      />
    )
  }
}
export default withRouter(AccountTabsPage)
