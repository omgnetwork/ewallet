import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter, Link } from 'react-router-dom'
import UserProvider from '../omg-users/userProvider'
import { compose } from 'recompose'
import TopNavigation from '../omg-page-layout/TopNavigation'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import moment from 'moment'
import { LoadingSkeleton, Breadcrumb, Button, Input } from '../omg-uikit'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import Copy from '../omg-copy'
import { connect } from 'react-redux'
import { updateUser } from '../omg-users/action'
const UserDetailContainer = styled.div`
  b {
    width: 150px;
    display: inline-block;
  }
`
const ContentDetailContainer = styled.div`
  display: flex;
  flex-wrap: wrap;
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
    return (
      <>
        {this.props.withBreadCrumb && (
          <BreadcrumbContainer>
            <Breadcrumb
              items={[
                <Link key='users' to={'/users/'}>
                  Users
                </Link>,
                user.email || user.username || user.provider_user_id
              ]}
            />
          </BreadcrumbContainer>
        )}
        <TopNavigation
          divider={false}
          title={user.email || user.username || user.provider_user_id}
          secondaryAction={false}
          buttons={this.renderButtons()}
        />
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
          <b style={{ verticalAlign: this.state.editing ? 'middle' : 'baseline' }}>Username:</b>{' '}
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
          <b>Provider ID:</b>{' '}<span>{user.provider_user_id || '-'}</span>
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
        <ContentDetailContainer>
          <DetailContainer>{this.renderDetail(user)}</DetailContainer>
          {wallet && <DetailContainer>{this.renderWallet(wallet)}</DetailContainer>}
        </ContentDetailContainer>
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
