import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter, Link } from 'react-router-dom'
import WalletProvider from '../omg-wallet/walletProvider'
import { compose } from 'recompose'
import { Button, Icon } from '../omg-uikit'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import moment from 'moment'
import CreateTransactionModal from '../omg-create-transaction-modal'
import { formatReceiveAmountToTotal } from '../utils/formatter'
const WalletDetailContainer = styled.div`
  padding-bottom: 20px;
  button i {
    margin-right: 10px;
  }
`
const ContentDetailContainer = styled.div`
  margin-top: 40px;
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
  button {
    padding-left: 40px;
    padding-right: 40px;
  }
`

const enhance = compose(
  withTheme,
  withRouter
)
class WalletDetaillPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    theme: PropTypes.object
  }
  state = {
    createTransactionModalOpen: false
  }
  onRequestClose = () => {
    this.setState({ createTransactionModalOpen: false })
  }
  onClickCreateTransaction = e => {
    this.setState({ createTransactionModalOpen: true })
  }
  renderTopBar = wallet => {
    return (
      <TopBar
        title={wallet.name}
        breadcrumbItems={['Wallet', `${wallet.address}`]}
        buttons={[
          <Button size='small' onClick={this.onClickCreateTransaction} key='transfer'>
            <Icon name='Transaction' /><span>Transfer</span>
          </Button>
        ]}
      />
    )
  }
  renderDetail = wallet => {
    const accountId = this.props.match.params.accountId
    return (
      <Section title='DETAILS'>
        <DetailGroup>
          <b>Address:</b> <span>{wallet.address}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Wallet Type:</b> <span>{wallet.identifier}</span>
        </DetailGroup>
        { wallet.account && <DetailGroup>
          <b>Account Owner:</b>{' '}
          <Link to={`/${accountId}/accounts/${wallet.account.id}`}>
            {_.get(wallet, 'account.name', '-')}
          </Link>
        </DetailGroup>}
        { wallet.user && <DetailGroup>
          <b>User:</b>{' '}
          <Link to={`/${accountId}/users/${wallet.user.id}`}>
            {_.get(wallet, 'user.id', '-')}
          </Link>
        </DetailGroup>}
        <DetailGroup>
          <b>Created Date:</b>{' '}
          <span>{moment(wallet.created_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Last Update:</b> <span>{moment(wallet.updated_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
      </Section>
    )
  }
  renderBalances = wallet => {
    return (
      <Section title='BALANCES'>
        {wallet.balances.map(balance => {
          return (
            <DetailGroup key={balance.token.id}>
              <b>{balance.token.name}</b>{' '}
              <span>{formatReceiveAmountToTotal(balance.amount, balance.token.subunit_to_unit)} {balance.token.symbol}</span>
            </DetailGroup>
          )
        })}
      </Section>
    )
  }
  renderWalletDetailContainer = wallet => {
    const accountId = this.props.match.params.accountId
    return (
      <DetailLayout backPath={`/${accountId}/wallets`}>
        <ContentContainer>
          {this.renderTopBar(wallet)}
          <ContentDetailContainer>
            <DetailContainer>{this.renderDetail(wallet)}</DetailContainer>
            <DetailContainer>{this.renderBalances(wallet)}</DetailContainer>
          </ContentDetailContainer>
        </ContentContainer>
        <CreateTransactionModal
          fromAddress={wallet.address}
          onRequestClose={this.onRequestClose}
          open={this.state.createTransactionModalOpen}
        />
      </DetailLayout>
    )
  }

  renderWalletDetailPage = ({ wallet }) => {
    return (
      <WalletDetailContainer>
        {wallet ? this.renderWalletDetailContainer(wallet) : null}
      </WalletDetailContainer>
    )
  }
  render () {
    return (
      <WalletProvider
        render={this.renderWalletDetailPage}
        walletAddress={this.props.match.params.walletAddress}
        {...this.state}
      />
    )
  }
}

export default enhance(WalletDetaillPage)
