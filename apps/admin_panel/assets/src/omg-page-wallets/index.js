import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import moment from 'moment'
import queryString from 'query-string'

import TopNavigation from '../omg-page-layout/TopNavigation'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import WalletsFetcher from '../omg-wallet/allWalletsFetcher'
import { selectWallets } from '../omg-wallet/selector'
import Copy from '../omg-copy'
import CreateTransactionModal from '../omg-create-transaction-modal'
import CreateWalletModal from '../omg-create-wallet-modal'

const WalletPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  > div {
    flex: 1;
  }
  td {
    white-space: nowrap;
  }
  td:nth-child(1) {
    border: none;
    position: relative;
    :before {
      content: '';
      position: absolute;
      right: 0;
      bottom: -1px;
      height: 1px;
      width: calc(100% - 50px);
      border-bottom: 1px solid ${props => props.theme.colors.S200};
    }
  }
  td:nth-child(1),
  td:nth-child(2),
  td:nth-child(3),
  td:nth-child(4), 
  td:nth-child(5), {
    width: 20%;
  }
  tbody td:first-child {
    border-bottom: none;
  }
`

const WalletAddressContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i[name='Wallet'] {
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
    margin-right: 10px;
  }
  i[name='Copy'] {
    visibility: hidden;
    margin-left: 5px;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B300};
    }
  }
`
const SortableTableContainer = styled.div`
  position: relative;
`
const StyledIcon = styled.span`
  i {
    margin-top: -3px;
    margin-right: 10px;
    margin-top
    font-size: 14px;
    font-weight: 400;
  }
`
class WalletPage extends Component {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    walletQuery: PropTypes.object,
    transferButton: PropTypes.bool,
    onClickRow: PropTypes.func,
    fetcher: PropTypes.func,
    title: PropTypes.string,
    divider: PropTypes.bool,
    match: PropTypes.shape({
      params: PropTypes.shape({
        accountId: PropTypes.string
      })
    })
  }
  static defaultProps = {
    walletQuery: {},
    transferButton: false,
    fetcher: WalletsFetcher,
    title: 'Wallets'
  }

  state = {
    transferModalOpen: false,
    createWalletModalOpen: false
  }

  onClickTransfer = () => {
    this.setState({ transferModalOpen: true })
  }
  onClickCreateWallet = () => {
    this.setState({ createWalletModalOpen: true })
  }
  onRequestCloseTransferModal = () => {
    this.setState({
      transferModalOpen: false,
      createWalletModalOpen: false
    })
  }
  renderTransferButton = () => {
    return (
      <Button size='small' onClick={this.onClickTransfer} key={'transfer'}>
        <Icon name='Transaction' />
        <span>Transfer</span>
      </Button>
    )
  }
  renderCreateWalletButton = () => {
    return (
      <Button
        key='create-wallet'
        styleType='secondary'
        size='small'
        onClick={this.onClickCreateWallet}
      >
        <Icon name='Plus' /><span>Create Wallet</span>
      </Button>
    )
  }
  getColumns = wallets => {
    return [
      { key: 'name', title: 'NAME', sort: true },
      { key: 'identifier', title: 'TYPE', sort: true },
      { key: 'address', title: 'ADDRESS', sort: true },
      { key: 'owner', title: 'OWNER', sort: true },
      { key: 'created_at', title: 'CREATED AT', sort: true }
    ]
  }
  getOwner = wallet => {
    return (
      <span>
        {wallet.account &&
          <span>
            <StyledIcon><Icon name='Merchant' /></StyledIcon>
            {wallet.account.name}
          </span>

        }
        {wallet.user && wallet.user.email &&
          <span>
            <StyledIcon><Icon name='People' /></StyledIcon>
            {wallet.user.email}
          </span>
        }
        {wallet.user && wallet.user.provider_user_id &&
          <span>
            <StyledIcon><Icon name='People' /></StyledIcon>
            {wallet.user.provider_user_id}
          </span>
        }
        {wallet.address === 'gnis000000000000' &&
          <span>
            <StyledIcon><Icon name='Token' /></StyledIcon>
            Genesis
          </span>
        }
      </span>
    )
  }
  getRow = wallets => {
    return selectWallets(
      {
        wallets: wallets.map(wallet => {
          return {
            owner: this.getOwner(wallet),
            id: wallet.address,
            ...wallet
          }
        })
      },
      queryString.parse(this.props.location.search).search
    )
  }
  onClickRow = (data, index) => e => {
    this.props.history.push(`/wallets/${data.address}`)
  }
  rowRenderer (key, data, rows) {
    if (key === 'name') {
      return (
        <WalletAddressContainer>
          <Icon name='Wallet' />
          <span>{data}</span>
        </WalletAddressContainer>
      )
    }
    if (key === 'created_at') {
      return moment(data).format()
    }
    if (key === 'identifier') {
      return (
        <WalletAddressContainer>
          <span>{data.split('_')[0]}</span>
        </WalletAddressContainer>
      )
    }
    if (key === 'address') {
      return (
        <WalletAddressContainer>
          <span>{data}</span> <Copy data={data} />
        </WalletAddressContainer>
      )
    }
    return data
  }

  renderWalletPage = ({ data: wallets, individualLoadingStatus, pagination, fetch }) => {
    const isAccountWalletsPage = queryString.parse(this.props.location.search).walletType !== 'user'
    const { accountId } = this.props.match.params

    return (
      <WalletPageContainer>
        <TopNavigation
          divider={this.props.divider}
          title={this.props.title}
          buttons={[
            this.props.transferButton && this.renderTransferButton(),
            isAccountWalletsPage && accountId && this.renderCreateWalletButton()
          ]}
        />
        <SortableTableContainer ref={table => (this.table = table)}>
          <SortableTable
            rows={this.getRow(wallets)}
            columns={this.getColumns(wallets)}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            onClickRow={this.props.onClickRow || this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
          />
        </SortableTableContainer>
        <CreateTransactionModal
          open={this.state.transferModalOpen}
          onRequestClose={this.onRequestCloseTransferModal}
        />
        <CreateWalletModal
          isOpen={this.state.createWalletModalOpen}
          onRequestClose={this.onRequestCloseTransferModal}
          accountId={accountId}
          onCreateWallet={fetch}
        />
      </WalletPageContainer>
    )
  }

  render () {
    const Fetcher = this.props.fetcher
    return (
      <Fetcher
        {...this.state}
        {...this.props}
        render={this.renderWalletPage}
        query={{
          page: queryString.parse(this.props.location.search).page,
          perPage: Math.floor(window.innerHeight / 75),
          search: queryString.parse(this.props.location.search).search,
          ...this.props.walletQuery
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(WalletPage)
