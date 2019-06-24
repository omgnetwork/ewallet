import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { compose } from 'recompose'
import moment from 'moment'
import { connect } from 'react-redux'
import styled from 'styled-components'
import { withRouter, Link, Route, Switch } from 'react-router-dom'

import UserProvider from '../omg-users/userProvider'
import TopNavigation from '../omg-page-layout/TopNavigation'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import { LoadingSkeleton, Breadcrumb, Id, Button, Input, Tag } from '../omg-uikit'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import UserTransactions from './UserTransactions'
import UserActivityLog from './UserActivityLog'
import CreateTransactionButton from '../omg-transaction/CreateTransactionButton'
import SearchBar from '../omg-page-layout/SearchGroup'
import UserWallet from './UserWallets'

import { updateUser } from '../omg-users/action'
const UserDetailContainer = styled.div`
  b {
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
  white-space: nowrap;
`
const MenuContainer = styled.div`
  display: flex;
  margin-bottom: 20px;
  align-items: center;
  > div {
    flex: 1;
  }
`
const StyledInput = styled(Input)`
  display: inline-block;
  vertical-align: middle;
  width: auto;
`

const enhance = compose(
  withRouter,
  connect(
    null,
    { updateUser }
  )
)
class UserDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    divider: PropTypes.bool,
    withBreadCrumb: PropTypes.bool,
    updateUser: PropTypes.func.isRequired
  }
  state = {
    editing: false,
    saving: false
  }

  onClickSave = async () => {
    this.setState({ saving: true })
    const result = await this.props.updateUser({
      id: this.props.match.params.userId,
      username: this.state.editUsername
    })
    if (result.data) {
      this.setState({ editing: false, saving: false })
    } else {
      this.setState({ saving: false })
    }
  }

  renderButtons (admin) {
    return this.state.editing
      ? [
        <Button
          key='cancel'
          styleType='secondary'
          onClick={e =>
            this.setState({ editing: false, editUsername: undefined })
          }
        >
            Cancel
        </Button>,
        <Button
          key='save'
          onClick={this.onClickSave}
          disabled={!this.state.editUsername}
          loading={this.state.saving}
        >
            Save
        </Button>
      ]
      : [
        <Button key='edit' onClick={e => this.setState({ editing: true })}>
            Edit
        </Button>
      ]
  }

  renderTopBar = user => {
    const type = this.props.match.params.type
    const { accountId, userId } = this.props.match.params
    const basePath = accountId
      ? `/accounts/${accountId}/users/${userId}`
      : `/users/${userId}`
    return (
      <>
        {this.props.withBreadCrumb && (
          <BreadcrumbContainer>
            <Breadcrumb
              items={[
                <Link key='users' to={'/users/'}>
                  Users
                </Link>,
                user.email || user.username || user.id
              ]}
            />
          </BreadcrumbContainer>
        )}
        <TopNavigation
          divider={false}
          title={user.email || user.username || user.id}
          secondaryAction={false}
          buttons={[<CreateTransactionButton key={'create_transaction'} />]}
        />
        <MenuContainer>
          <UserDetailMenuContainer>
            <Link to={basePath}>
              <Tag active={type === 'details' || !type} title='Details' />
            </Link>
            <Link to={`${basePath}/wallets`}>
              <Tag active={type === 'wallets'} title='Wallets' />
            </Link>
            <Link to={`${basePath}/transactions`}>
              <Tag active={type === 'transactions'} title='Transactions' />
            </Link>
            <Link to={`${basePath}/logs`}>
              <Tag active={type === 'logs'} title='Logs' />
            </Link>
          </UserDetailMenuContainer>
          <SearchBar />
        </MenuContainer>
      </>
    )
  }
  renderDetail = user => {
    return (
      <DetailContainer>
        <DetailGroup>
          <b>ID:</b>
          <Id>{user.id}</Id>
        </DetailGroup>
        <DetailGroup>
          <b
            style={{
              verticalAlign: this.state.editing ? 'middle' : 'baseline'
            }}
          >
            Username:
          </b>{' '}
          {this.state.editing ? (
            <StyledInput
              normalPlaceholder='username...'
              value={this.state.editUsername || user.username || ''}
              onChange={e => this.setState({ editUsername: e.target.value })}
            />
          ) : (
            <span>{user.username || '-'}</span>
          )}
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
      </DetailContainer>
    )
  }
  renderWallet = wallet => {
    return (
      <Section title={{ text: 'Balance', icon: 'Token' }}>
        {wallet ? (
          <div>
            <DetailGroup>
              <b>Wallet Address:</b>{' '}
              <Link to={`/wallets/${wallet.address}`}>{wallet.address}</Link> ({' '}
              <span>{wallet.name}</span> )
            </DetailGroup>
            {wallet.balances.map(balance => {
              return (
                <DetailGroup key={balance.token.id}>
                  <b>{balance.token.name}</b>
                  <span>
                    {formatReceiveAmountToTotal(
                      balance.amount,
                      balance.token.subunit_to_unit
                    )}
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
            path={[
              '/users/:userId/',
              '/accounts/:accountId/users/:userId/details',
              '/accounts/:accountId/users/:userId'
            ]}
            render={() => this.renderDetail(user)}
            exact
          />
          <Route
            path={[
              '/users/:userId/wallets',
              '/accounts/:accountId/users/:userId/wallets'
            ]}
            render={UserWallet}
            exact
          />
          <Route
            path={[
              '/users/:userId/transactions',
              '/accounts/:accountId/users/:userId/transactions'
            ]}
            component={UserTransactions}
            exact
          />
          <Route
            path={[
              '/users/:userId/logs',
              '/accounts/:accountId/users/:userId/logs'
            ]}
            render={() => <UserActivityLog topNavigation={false} />}
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
