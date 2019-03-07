import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter, Link } from 'react-router-dom'
import AccountProvider from '../omg-account/accountProvider'
import WalletsFetcherByAccountId from '../omg-wallet/walletsFetcher'
import { compose } from 'recompose'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import moment from 'moment'
import Copy from '../omg-copy'
const AccountDetailContainer = styled.div``
const ContentDetailContainer = styled.div`
  margin-top: 40px;
  display: flex;
  > div {
    flex: 0 1 50%;
  }
`
const ContentContainer = styled.div`
  display: inline-block;
  width: 100%;
`
const WalletCointainter = styled.div`
  b {
    text-transform: capitalize;
  }
`
const TokensContainer = styled.div`
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
          <b>ID:</b> {account.id} <Copy data={account.id} />
        </DetailGroup>
        <DetailGroup>
          <b>Description:</b> {account.description || '-'}
        </DetailGroup>
        <DetailGroup>
          <b>Category:</b> {_.get(account.categories, 'data[0].name', '-')}
        </DetailGroup>
        <DetailGroup>
          <b>Created Date:</b> {moment(account.created_at).format()}
        </DetailGroup>
        <DetailGroup>
          <b>Last Update:</b> {moment(account.updated_at).format()}
        </DetailGroup>
      </Section>
    )
  }
  renderWallets = () => {
    const accountId = this.props.match.params.accountId
    return (
      <Section title='WALLETS'>
        <WalletsFetcherByAccountId
          query={{ accountId }}
          render={({ data }) => {
            return data.map(wallet => {
              return (
                <WalletCointainter key={wallet.address}>
                  <DetailGroup>
                    <b>{wallet.name} Wallet</b>
                    <Link to={`/${accountId}/wallets/${wallet.address}`}>{wallet.address}</Link>
                  </DetailGroup>
                  {!!wallet.balances.filter(b => b.amount).length && (
                    <TokensContainer>
                      {wallet.balances
                        .filter(b => b.amount)
                        .map(balance => {
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
                    </TokensContainer>
                  )}
                </WalletCointainter>
              )
            })
          }}
        />
      </Section>
    )
  }
  renderAccountDetailContainer = account => {
    return (
      <ContentContainer>
        <ContentDetailContainer>{this.renderDetail(account)}</ContentDetailContainer>
      </ContentContainer>
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
        {...this.props}
        render={this.renderAccountDetailPage}
        accountId={this.props.match.params.accountId}
      />
    )
  }
}

export default enhance(AccountDetailPage)
