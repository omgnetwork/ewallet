import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled, { withTheme } from 'styled-components'
import { withRouter } from 'react-router-dom'
import WalletProvider from '../omg-wallet/walletProvider'
import { compose } from 'recompose'
import { Button } from '../omg-uikit'
import Section, { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import TopBar from '../omg-page-detail-layout/TopBarDetail'
import DetailLayout from '../omg-page-detail-layout/DetailLayout'
import moment from 'moment'
import CreateTransactionModal from '../omg-create-transaction-modal'
const AccountDetailContainer = styled.div`
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

const enhnace = compose(
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
    createTransactionModalOpen: false
  }
  onRequestClose = () => {
    this.setState({ createTransactionModalOpen: false })
  }
  onClickMintTopen = e => {
    this.setState({ createTransactionModalOpen: true })
  }
  renderTopBar = wallet => {
    return (
      <TopBar
        title={wallet.name}
        breadcrumbItems={['Wallet', `${wallet.address}`]}
        buttons={[
          <Button size='small' onClick={this.onClickMintTopen} key='transfer'>
            <span>Transfer</span>
          </Button>
        ]}
      />
    )
  }
  renderDetail = wallet => {
    return (
      <Section title='DETAILS'>
        <DetailGroup>
          <b>Address:</b> <span>{wallet.address}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Wallet Type:</b> <span>{wallet.identifier}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Account Owner:</b> <span>{wallet.account_id}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Created date:</b> <span>{moment(wallet.created_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Last update:</b> <span>{moment(wallet.updated_at).format('DD/MM/YYYY hh:mm:ss')}</span>
        </DetailGroup>
      </Section>
    )
  }
  renderAccountDetailContainer = wallet => {
    const accountId = this.props.match.params.walletId
    return (
      <DetailLayout backPath={`/${accountId}/wallets`}>
        <ContentContainer>
          {this.renderTopBar(wallet)}
          <ContentDetailContainer>
            <DetailContainer>{this.renderDetail(wallet)}</DetailContainer>
          </ContentDetailContainer>
        </ContentContainer>
        <CreateTransactionModal
          wallet={wallet}
          onRequestClose={this.onRequestClose}
          open={this.state.createTransactionModalOpen}
        />
      </DetailLayout>
    )
  }

  renderWalletDetailPage = ({ wallet }) => {
    return (
      <AccountDetailContainer>
        {wallet ? this.renderAccountDetailContainer(wallet) : 'loading'}
      </AccountDetailContainer>
    )
  }
  render () {
    return (
      <WalletProvider
        render={this.renderWalletDetailPage}
        walletId={this.props.match.params.walletId}
        {...this.state}
      />
    )
  }
}

export default enhnace(TokenDetailPage)
