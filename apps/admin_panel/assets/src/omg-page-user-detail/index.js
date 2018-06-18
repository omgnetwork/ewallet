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
    return (
      <TopBar
        title={user.id}
        breadcrumbItems={['User', user.id]}
        buttons={[
          <Button size='small' onClick={this.onClickMintTopen}>
            <span>Mint Token</span>
          </Button>
        ]}
      />
    )
  }
  renderDetail = user => {
    return (
      <Section title='DETAILS'>
        <DetailGroup>
          <b>Symbol:</b> <span>{user.symbol}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Decimal:</b> <span>{Math.log10(user.subunit_to_unit)}</span>
        </DetailGroup>
        <DetailGroup>
          <b>ID:</b> <span>{user.id}</span>
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
  renderUserDetailContainer = token => {
    const accountId = this.props.match.params.accountId
    return (
      <DetailLayout backPath={`/${accountId}/users`}>
        <ContentContainer>
          {this.renderTopBar(token)}
          <ContentDetailContainer>
            <DetailContainer>{this.renderDetail(token)}</DetailContainer>
          </ContentDetailContainer>
        </ContentContainer>
        <MintTokenModal
          token={token}
          onRequestClose={this.onRequestClose}
          open={this.state.mintTokenModalOpen}
        />
      </DetailLayout>
    )
  }

  renderUserDetailPage = ({ user }) => {
    return (
      <UserDetailContainer>
        {user ? this.renderUserDetailContainer(user) : 'loading'}
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
