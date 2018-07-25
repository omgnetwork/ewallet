import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter, Link } from 'react-router-dom'
import UserProvider from '../omg-users/userProvider'
import { compose } from 'recompose'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import moment from 'moment'
import { LoadingSkeleton } from '../omg-uikit'
import { formatReceiveAmountToTotal } from '../utils/formatter'
const UserDetailContainer = styled.div`
  padding-bottom: 20px;
  b {
    width: 150px;
    display: inline-block;
  }
`
const ContentDetailContainer = styled.div`
  margin-top: 40px;
  display: flex;
`
const DetailContainer = styled.div`
  flex: 0 1 50%;
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

const enhance = compose(
  withTheme,
  withRouter
)
class TokenDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    theme: PropTypes.object
  }
  renderTopBar = user => {
    return <TopBar title={user.id} breadcrumbItems={['User', user.id]} buttons={[]} />
  }
  renderDetail = user => {
    return (
      <Section title='DETAILS'>
        <DetailGroup>
          <b>Id:</b> <span>{user.id}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Email:</b> <span>{user.email || '-'}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Provider Id:</b> <span>{user.provider_user_id}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Created Date:</b> <span>{moment(user.created_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Last Update:</b> <span>{moment(user.updated_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
      </Section>
    )
  }
  renderWallet = wallet => {
    const accountId = this.props.match.params.accountId
    return (
      <Section title='BALANCE'>
        {wallet ? (
          <div>
            <DetailGroup>
              <b>Wallet Address:</b>{' '}
              <Link to={`/${accountId}/wallets/${wallet.address}`}>{wallet.address}</Link> ({' '}
              <span>{wallet.name}</span> )
            </DetailGroup>
            {wallet.balances.map(balance => {
              return (
                <DetailGroup key={balance.token.id}>
                  <b>{balance.token.name}</b>
                  <span>{formatReceiveAmountToTotal(balance.amount, balance.token.subunit_to_unit)}</span>{' '}
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
    const accountId = this.props.match.params.accountId
    return (
      <DetailLayout backPath={`/${accountId}/users`}>
        <ContentContainer>
          {this.renderTopBar(user)}
          <ContentDetailContainer>
            <DetailContainer>{this.renderDetail(user)}</DetailContainer>
            <DetailContainer>{this.renderWallet(wallet)}</DetailContainer>
          </ContentDetailContainer>
        </ContentContainer>
      </DetailLayout>
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

export default enhance(TokenDetailPage)
