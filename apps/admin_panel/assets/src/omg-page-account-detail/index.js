import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter, Link } from 'react-router-dom'
import AccountProvider from '../omg-account/accountProvider'
import WalletsFetcherByAccountId from '../omg-wallet/walletsFetcher'
import { compose } from 'recompose'
import { formatNumber } from '../utils/formatter'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import moment from 'moment'
const AccountDetailContainer = styled.div`
  padding: 20px 0;
`
const ContentDetailContainer = styled.div`
  margin-top: 50px;
  display: flex;
`
const ContentContainer = styled.div`
  display: inline-block;
  width: 100%;
`
const WalletCointainter = styled.div`
  margin-bottom: 40px;
`
const enhance = compose(
  withTheme,
  withRouter
)
class AccountDetailPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    theme: PropTypes.object
  }
  renderTopBar = account => {
    return <TopBar title={account.name} breadcrumbItems={['Account', account.name]} />
  }
  renderDetail = account => {
    return (
      <Section title='DETAILS'>
        <DetailGroup>
          <b>ID:</b> {account.id}
        </DetailGroup>
        <DetailGroup>
          <b>Description:</b> {account.description || '-'}
        </DetailGroup>
        <DetailGroup>
          <b>Category:</b> {_.get(account.categories, 'data[0].name', '-')}
        </DetailGroup>
        <DetailGroup>
          <b>Created date:</b> {moment(account.created_at).format('DD/MM/YYYY hh:mm:ss')}
        </DetailGroup>
        <DetailGroup>
          <b>Last update:</b> {moment(account.updated_at).format('DD/MM/YYYY hh:mm:ss')}
        </DetailGroup>
      </Section>
    )
  }
  renderWallets = () => {
    const accountId = this.props.match.params.accountId
    return (
      <Section title='WALLETS'>
        <WalletsFetcherByAccountId
          accountId={this.props.match.params.accountId}
          render={({ data, individualLoadingStatus }) => {
            return data.map(wallet => {
              return (
                <WalletCointainter>
                  <DetailGroup >
                    <b>Address: </b>
                    <Link to={`/${accountId}/wallet/${wallet.address}`}>{wallet.address}</Link>
                    {' '} ( <span>{wallet.name}</span> )
                  </DetailGroup>
                  {wallet.balances.filter(b => b.amount).map(balance => {
                    return (
                      <DetailGroup key={balance.token.id}>
                        <b>{balance.token.name}</b>
                        <span>
                          {formatNumber(balance.amount / balance.token.subunit_to_unit)}
                        </span>{' '}
                        <span>{balance.token.symbol}</span>
                      </DetailGroup>
                    )
                  })}
                </WalletCointainter>
              )
            })
          }}
        />
      </Section>
    )
  }
  renderAccountDetailContainer = account => {
    const accountId = this.props.match.params.accountId
    return (
      <DetailLayout backPath={`/${accountId}/accounts`}>
        <ContentContainer>
          {this.renderTopBar(account)}
          <ContentDetailContainer>
            {this.renderDetail(account)}
            {this.renderWallets()}
          </ContentDetailContainer>
        </ContentContainer>
      </DetailLayout>
    )
  }

  renderAccountDetailPage = ({ account, loadingStatus }) => {
    return (
      <AccountDetailContainer>
        {account && this.renderAccountDetailContainer(account)}
      </AccountDetailContainer>
    )
  }
  render () {
    return (
      <AccountProvider
        render={this.renderAccountDetailPage}
        accountId={this.props.match.params.viewAccountId}
      />
    )
  }
}

export default enhance(AccountDetailPage)
