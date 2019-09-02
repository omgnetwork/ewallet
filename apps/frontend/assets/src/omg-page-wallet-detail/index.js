import React, { Component } from 'react'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter, Link, Route, Switch } from 'react-router-dom'
import { compose } from 'recompose'
import moment from 'moment'

import { Tag, Button, Icon } from '../omg-uikit'
import { enableMetamaskEthereumConnection } from '../omg-web3/action'
import { selectMetamaskUsable } from '../omg-web3/selector'
import { generateDepositAddress } from '../omg-wallet/action'
import WalletProvider from '../omg-wallet/walletProvider'
import CreateTransactionButton from '../omg-transaction/CreateTransactionButton'
import CreateInternalToExternalButton from '../omg-transaction/CreateInternalToExternalButton'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { DetailGroup } from '../omg-page-detail-layout/DetailSection'
import WalletBalance from './WalletBalances'
import Copy from '../omg-copy'
import CONSTANT from '../constants'
import WalletTransactions from './WalletTransaction'

const WalletDetailContainer = styled.div`
  padding-bottom: 20px;
  button i {
    margin-right: 10px;
  }
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
const ErrorPageContainer = styled.div`
  text-align: center;
  h4 {
    margin-top: 20px;
  }
  img {
    margin-top: 100px;
    width: 500px;
    height: 350px;
    margin-bottom: 30px;
  }
`

const MenuContainer = styled.div`
  display: flex;
  margin-bottom: 20px;
  align-items: center;
  > div {
    flex: 1;
  }
`

const enhance = compose(
  withRouter,
  connect(
    state => ({ metamaskUsable: selectMetamaskUsable(state) }),
    { generateDepositAddress, enableMetamaskEthereumConnection }
  )
)
class WalletDetaillPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    divider: PropTypes.bool,
    generateDepositAddress: PropTypes.func,
    enableMetamaskEthereumConnection: PropTypes.func,
    metamaskUsable: PropTypes.bool
  }
  renderInternalToExternalButton = wallet => {
    if (this.props.metamaskUsable) {
      return (
        <CreateInternalToExternalButton
          wallet={wallet}
          key='internalToExternal'
        />
      )
    }
    return (
      <Button
        key='create'
        size='small'
        styleType='primary'
        onClick={this.props.enableMetamaskEthereumConnection}
        disabled={!window.ethereum || !window.web3}
      >
        <Icon name='Transaction' />
        <span>External Transfer</span>
      </Button>
    )
  }
  renderTopBar = wallet => {
    return (
      <TopNavigation
        searchBar={false}
        divider={this.props.divider}
        title={wallet.name}
        buttons={[
          this.renderInternalToExternalButton(wallet),
          <CreateTransactionButton
            fromAddress={wallet.address}
            key='transfer'
          />
        ]}
      />
    )
  }
  renderDetail = wallet => {
    return (
      <DetailContainer>
        <DetailGroup>
          <b>Address:</b> <span>{wallet.address}</span>{' '}
          <Copy data={wallet.address} />
        </DetailGroup>
        <DetailGroup>
          <b>Name:</b> <span>{wallet.name}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Wallet Identifier:</b> <span>{wallet.identifier}</span>
        </DetailGroup>
        {wallet.account && (
          <DetailGroup>
            <b>Account Owner:</b>{' '}
            <Link to={`/accounts/${wallet.account.id}/details`}>
              {_.get(wallet, 'account.name', '-')}
            </Link>
          </DetailGroup>
        )}
        {wallet.user && (
          <DetailGroup>
            <b>User:</b>{' '}
            <Link to={`/users/${wallet.user.id}`}>
              {_.get(wallet, 'user.id', '-')}
            </Link>
          </DetailGroup>
        )}
        {(!wallet.identifier.includes('burn') && !wallet.identifier.includes('genesis')) && (
          <DetailGroup>
            <b>Blockchain Address:</b>{' '}
            {wallet.blockchain_deposit_address && (
              <>
                <span>{wallet.blockchain_deposit_address}</span> <Copy data={wallet.blockchain_deposit_address} />
              </>
            )}
            {!wallet.blockchain_deposit_address && (
              <a onClick={() => this.props.generateDepositAddress(wallet.address)}>
                Generate deposit address
              </a>
            )}
          </DetailGroup>
        )}
        <DetailGroup>
          <b>Created At:</b> <span>{moment(wallet.created_at).format()}</span>
        </DetailGroup>
        <DetailGroup>
          <b>Updated At:</b> <span>{moment(wallet.updated_at).format()}</span>
        </DetailGroup>
      </DetailContainer>
    )
  }
  renderWalletDetailContainer = wallet => {
    const type = this.props.match.params.type
    const { walletAddress, accountId } = this.props.match.params
    const basePath = accountId
      ? `/accounts/${accountId}/wallets/${walletAddress}`
      : `/wallets/${walletAddress}`
    return (
      <div>
        <ContentContainer>
          {this.renderTopBar(wallet)}
          <MenuContainer>
            <div>
              <Link to={basePath}>
                <Tag active={type === 'details' || !type} title='Details' />
              </Link>
              <Link to={`${basePath}/balances`}>
                <Tag active={type === 'balances'} title='Balances' />
              </Link>
              <Link to={`${basePath}/transactions`}>
                <Tag active={type === 'transactions'} title='Transactions' />
              </Link>
            </div>
          </MenuContainer>

          <Switch>
            <Route
              path={[
                '/wallets/:walletAddress/balances',
                '/accounts/:accountId/wallets/:walletAddress/balances'
              ]}
              render={() => (
                <DetailContainer>
                  <WalletBalance wallet={wallet} />{' '}
                </DetailContainer>
              )}
              exact
            />
            <Route
              path={[
                '/wallets/:walletAddress',
                '/accounts/:accountId/wallets/:walletAddress'
              ]}
              render={() => this.renderDetail(wallet)}
              exact
            />
            <Route
              path={[
                '/wallets/:walletAddress/transactions',
                '/accounts/:accountId/wallets/:walletAddress/transactions'
              ]}
              component={WalletTransactions}
              exact
            />
          </Switch>
        </ContentContainer>
      </div>
    )
  }
  renderErrorPage (error) {
    return (
      <ErrorPageContainer>
        <img src={require('../../statics/images/empty_state.png')} />
        <h2>{error.code}</h2>
        <p>{error.description}</p>
      </ErrorPageContainer>
    )
  }

  renderWalletDetailPage = ({ wallet, loadingStatus, result }) => {
    return (
      <WalletDetailContainer>
        {wallet
          ? this.renderWalletDetailContainer(wallet)
          : loadingStatus === CONSTANT.LOADING_STATUS.FAILED &&
            this.renderErrorPage(result.error)}
      </WalletDetailContainer>
    )
  }
  render () {
    return (
      <WalletProvider
        render={this.renderWalletDetailPage}
        walletAddress={this.props.match.params.walletAddress}
        {...this.props}
      />
    )
  }
}

export default enhance(WalletDetaillPage)
