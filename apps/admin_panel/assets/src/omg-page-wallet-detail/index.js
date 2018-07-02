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
import { formatNumber } from '../utils/formatter'
const WalletDetailContainer = styled.div`
  padding-bottom: 20px;
  padding-top: 3px;
  b {
    width: 150px;
    display: inline-block;
  }
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
            <Icon name='Transfer' /><span>Transfer</span>
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
        <DetailGroup>
          <b>Account Owner:</b>{' '}
          <Link to={`/${accountId}/account/${wallet.account.id}`}>
            {_.get(wallet, 'account.name', '-')}
          </Link>
        </DetailGroup>
        <DetailGroup>
          <b>Created date:</b>{' '}
          <span>{moment(wallet.created_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Last update:</b> <span>{moment(wallet.updated_at).format('DD/MM/YYYY hh:mm:ss')}</span>
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
              <span>{formatNumber(balance.amount / balance.token.subunit_to_unit)}</span> {balance.token.symbol}
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
