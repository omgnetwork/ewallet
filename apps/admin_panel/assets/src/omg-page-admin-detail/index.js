import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter, Link } from 'react-router-dom'
import AdminProvider from '../omg-admins/adminProvider'
import { compose } from 'recompose'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import moment from 'moment'
import { LoadingSkeleton } from '../omg-uikit'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import Copy from '../omg-copy'
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
  flex: 1 1 50%;
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
    match: PropTypes.object
  }
  renderTopBar = admin => {
    return <TopBar title={admin.id} breadcrumbItems={['Admin', admin.id]} buttons={[]} />
  }
  renderDetail = admin => {
    return (
      <Section title='DETAILS'>
        <DetailGroup>
          <b>Id:</b> <span>{admin.id}</span> <Copy data={admin.id} />
        </DetailGroup>
        <DetailGroup>
          <b>Email:</b> <span>{admin.email || '-'}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Created Date:</b> <span>{moment(admin.created_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Last Update:</b> <span>{moment(admin.updated_at).format('DD/MM/YYYY hh:mm:ss')}</span>
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
  renderUserDetailContainer = admin => {
    return (
      <DetailLayout backPath={'/users'}>
        <ContentContainer>
          {this.renderTopBar(admin)}
          <ContentDetailContainer>
            <DetailContainer>{this.renderDetail(admin)}</DetailContainer>
          </ContentDetailContainer>
        </ContentContainer>
      </DetailLayout>
    )
  }

  renderUserDetailPage = ({ admin }) => {
    return (
      <UserDetailContainer>
        {admin ? this.renderUserDetailContainer(admin) : null}
      </UserDetailContainer>
    )
  }
  render () {
    return (
      <AdminProvider
        render={this.renderUserDetailPage}
        adminId={this.props.match.params.adminId}
        {...this.state}
        {...this.props}
      />
    )
  }
}

export default enhance(TokenDetailPage)
