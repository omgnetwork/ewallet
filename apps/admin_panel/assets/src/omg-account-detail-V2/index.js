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
import { consumptionsAccountFetcher } from '../omg-consumption/consumptionsFetcher'
import { getUsersByAccountId } from '../omg-users/usersFetcher'
import adminsAccountFetcher from '../omg-member/MembersFetcher'
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

  renderDetailPage () {
    return <DetailPage />
  }
  renderWalletPage () {
    return (
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
  }
  renderTransactionRequestPage () {
    return (
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
  }
  renderConsumptionPage () {
    return (
      <ConsumptionPage
        fetcher={consumptionsAccountFetcher}
        accountId={this.props.match.params.accountId}
      />
    )
  }
  renderTransactionPage () {
    return (
      <TransactionPage
        query={{
          matchAny: [
            {
              field: 'from_account.id',
              comparator: 'eq',
              value: this.props.match.params.accountId
            },
            {
              field: 'to_account.id',
              comparator: 'eq',
              value: this.props.match.params.accountId
            }
          ]
        }}
      />
    )
  }
  renderUserPage () {
    return <UserPage fetcher={getUsersByAccountId} accountId={this.props.match.params.accountId} />
  }
  renderAdminPage () {
    return (
      <AdminPage
        fetcher={adminsAccountFetcher}
        accountId={this.props.match.params.accountId}
        navigation={false}
      />
    )
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
              content: this.renderDetailPage()
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/wallets`}>Wallets</Link>
              ),
              content: this.renderWalletPage()
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/requests`}>Requests</Link>
              ),
              content: this.renderTransactionRequestPage()
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/consumptions`}>
                  Consumption
                </Link>
              ),
              content: this.renderConsumptionPage()
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/transactions`}>
                  Transactions
                </Link>
              ),
              content: this.renderTransactionPage()
            },
            {
              title: <Link to={`/accounts/${this.props.match.params.accountId}/users`}>Users</Link>,
              content: this.renderUserPage()
            },
            {
              title: (
                <Link to={`/accounts/${this.props.match.params.accountId}/admins`}>Admins</Link>
              ),
              content: this.renderAdminPage()
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
