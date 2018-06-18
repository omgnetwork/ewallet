import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter } from 'react-router-dom'
import UserProvider from '../omg-users/userProvider'
import { compose } from 'recompose'
import { Button } from '../omg-uikit'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import moment from 'moment'
import MintTokenModal from '../omg-mint-token-modal'
const UserDetailContainer = styled.div`
  padding-bottom: 20px;
  padding-top: 3px;
`
const ContentDetailContainer = styled.div`
  margin-top: 50px;
  display: flex;
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
  state = {
    mintTokenModalOpen: false
  }
  onRequestClose = () => {
    this.setState({ mintTokenModalOpen: false })
  }
  onClickMintTopen = e => {
    this.setState({ mintTokenModalOpen: true })
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
          <b>Created date:</b> <span>{moment(user.created_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Last update:</b> <span>{moment(user.updated_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
      </Section>
    )
  }
  renderWallet = wallet => {
    return (
      wallet && (
        <Section title='BALANCE'>
          <DetailGroup>
            <b>Wallet Address:</b> <span>{wallet.address}</span>
          </DetailGroup>
          {wallet.balances.map(balance => {
            return (
              <DetailGroup key={balance.token.id}>
                <b>{balance.token.name}</b>{' '}
                <span>{balance.amount / balance.token.subunit_to_unit}</span>
              </DetailGroup>
            )
          })}
        </Section>
      )
    )
  }
  renderUserDetailContainer = (user, wallet) => {
    const accountId = this.props.match.params.accountId
    return (
      <DetailLayout backPath={`/${accountId}/users`}>
        <ContentContainer>
          {this.renderTopBar(user)}
          <ContentDetailContainer>
            <DetailContainer>{this.renderWallet(wallet)}</DetailContainer>
            <DetailContainer>{this.renderDetail(user)}</DetailContainer>
          </ContentDetailContainer>
        </ContentContainer>
      </DetailLayout>
    )
  }

  renderUserDetailPage = ({ user, wallet }) => {
    return (
      <UserDetailContainer>
        {user ? this.renderUserDetailContainer(user, wallet) : 'loading'}
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
