import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter, Link, Route, Switch } from 'react-router-dom'
import queryString from 'query-string'
import UserProvider from '../omg-users/userProvider'
import { compose } from 'recompose'
import TopNavigation from '../omg-page-layout/TopNavigation'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import moment from 'moment'
import { LoadingSkeleton, Breadcrumb } from '../omg-uikit'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import Copy from '../omg-copy'
import { KeyButton } from '../omg-page-api'
import TransactionPage from './UserTransactions'
import UserActivityLogPage from './UserActivityLog'

const UserDetailContainer = styled.div`
  b {
    width: 150px;
    display: inline-block;
  }
`
const DetailContainer = styled.div`
  flex: 1 1 auto;
  :first-child {
    margin-right: 20px;
  }
`
const ContentContainer = styled.div`
  display: inline-block;
  width: 100%;
`
const LoadingContainer = styled.div`
  div {
    margin-bottom: 1em;
  }
`
const BreadcrumbContainer = styled.div`
  margin-top: 30px;
`
const UserDetailMenuContainer = styled.div`
  margin-bottom: 20px;
`

const enhance = compose(
  withTheme,
  withRouter
)
class UserDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    divider: PropTypes.bool,
    withBreadCrumb: PropTypes.bool
  }
  renderTopBar = user => {
    const type = this.props.match.params.type
    return (
      <>
        {this.props.withBreadCrumb && (
          <BreadcrumbContainer>
            <Breadcrumb
              items={[
                <Link key='users' to={'/users/'}>
                  Users
                </Link>,
                user.email || user.provider_user_id
              ]}
            />
          </BreadcrumbContainer>
        )}
        <TopNavigation
          divider={false}
          title={user.email || user.provider_user_id}
          secondaryAction={false}
        />
        <UserDetailMenuContainer>
          <Link to={`/users/${this.props.match.params.userId}`}>
            <KeyButton active={type === 'details' || !type}>Details</KeyButton>
          </Link>
          <Link to={`/users/${this.props.match.params.userId}/wallets`}>
            <KeyButton active={type === 'wallets'}>Wallets</KeyButton>
          </Link>
          <Link to={`/users/${this.props.match.params.userId}/transactions`}>
            <KeyButton active={type === 'transactions'}>Transactions</KeyButton>
          </Link>
          <Link to={`/users/${this.props.match.params.userId}/logs`}>
            <KeyButton active={type === 'logs'}>Logs</KeyButton>
          </Link>
        </UserDetailMenuContainer>
      </>
    )
  }
  renderDetail = user => {
    return (
      <Section title={{ text: 'Details', icon: 'Portfolio' }}>
        <DetailGroup>
          <b>ID:</b> <span>{user.id}</span> <Copy data={user.id} />
        </DetailGroup>
        <DetailGroup>
          <b>Email:</b> <span>{user.email || '-'}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Provider ID:</b> <span>{user.provider_user_id || '-'}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Created At:</b> <span>{moment(user.created_at).format()}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Updated At:</b> <span>{moment(user.updated_at).format()}</span>
        </DetailGroup>
      </Section>
    )
  }
  renderWallet = wallet => {
    return (
      <Section title={{ text: 'Balance', icon: 'Token' }}>
        {wallet ? (
          <div>
            <DetailGroup>
              <b>Wallet Address:</b> <Link to={`/wallets/${wallet.address}`}>{wallet.address}</Link>{' '}
              ( <span>{wallet.name}</span> )
            </DetailGroup>
            {wallet.balances.map(balance => {
              return (
                <DetailGroup key={balance.token.id}>
                  <b>{balance.token.name}</b>
                  <span>
                    {formatReceiveAmountToTotal(balance.amount, balance.token.subunit_to_unit)}
                  </span>{' '}
                  <span>{balance.token.symbol}</span>
                </DetailGroup>
              )
            })}
          </div>
        ) : (
          <LoadingContainer>
            <LoadingSkeleton />
            <LoadingSkeleton />
            <LoadingSkeleton />
          </LoadingContainer>
        )}
      </Section>
    )
  }
  renderUserDetailContainer = (user, wallet) => {
    return (
      <ContentContainer>
        {this.renderTopBar(user)}
        <Switch>
          <Route
            path={'/users/:userId/'}
            render={() => <DetailContainer>{this.renderDetail(user)}</DetailContainer>}
            exact
          />
          <Route path={'/users/:userId/wallets'} render={() => this.renderWallet(wallet)} exact />
          <Route
            path={'/users/:userId/transactions'}
            render={() => <TransactionPage topNavigation={false} />}
            exact
          />
          <Route
            path={'/users/:userId/logs'}
            render={() => <UserActivityLogPage topNavigation={false} />}
            exact
          />
        </Switch>
      </ContentContainer>
    )
  }

  renderUserDetailPage = ({ user, wallet }) => {
    return (
      <UserDetailContainer>
        {user ? this.renderUserDetailContainer(user, wallet) : null}
      </UserDetailContainer>
    )
  }
  render () {
    return (
      <UserProvider
        render={this.renderUserDetailPage}
        userId={this.props.match.params.userId}
        {...this.state}
        {...this.props}
      />
    )
  }
}

export default enhance(UserDetailPage)
