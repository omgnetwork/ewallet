import React, { Component } from 'react'
import PropTypes from 'prop-types'
import TabsManager from '../omg-tabs'
import AccountProvider from '../omg-account/accountProvider'
import { withRouter, Link } from 'react-router-dom'
import DetailPage from '../omg-page-account-detail'
import WalletPage from '../omg-page-wallets'
import styled from 'styled-components'
import { Avatar } from '../omg-uikit'
import TransactionRequestPage from '../omg-page-transaction-request'
import ConsumptionPage from '../omg-page-consumption'
import TransactionPage from '../omg-page-transaction'
import UserPage from '../omg-page-users'
import AdminPage from '../omg-page-admins'
import SettingPage from '../omg-page-account-setting'
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
    const tabs = {
      detail: 0,
      wallets: 1,
      requests: 2,
      consumptions: 3,
      transactions: 4,
      users: 5,
      admins: 6,
      setting: 7
    }
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
              content: (
                <WalletPage
                  walletQuery={{
                    matchAny: [
                      {
                        field: 'account.id',
                        comparator: 'eq',
                        value: this.props.match.params.accountId
                      },
                      {
                        field: 'account.id',
                        comparator: 'eq',
                        value: null
                      }
                    ]
                  }}
                />
              )
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/requests`}>Requests</Link>
              ),
              content: (
                <TransactionRequestPage
                  query={{
                    matchAny: [
                      {
                        field: 'account.id',
                        comparator: 'eq',
                        value: this.props.match.params.accountId
                      },
                      {
                        field: 'account.id',
                        comparator: 'eq',
                        value: null
                      }
                    ]
                  }}
                />
              )
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/consumptions`}>
                  Consumption
                </Link>
              ),
              content: <ConsumptionPage />
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/transactions`}>
                  Transactions
                </Link>
              ),
              content: <TransactionPage />
            },
            {
              title: <Link to={`/accounts/${this.props.match.params.accountId}/users`}>Users</Link>,
              content: <UserPage />
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/admins`}>Admins</Link>
              ),
              content: <AdminPage />
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/setting`}>Setting</Link>
              ),
              content: <SettingPage />
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
