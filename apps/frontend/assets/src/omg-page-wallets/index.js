import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'

import walletRowRenderer from './walletTableRowRenderer'
import TopNavigation from '../omg-page-layout/TopNavigation'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import WalletsFetcher from '../omg-wallet/allWalletsFetcher'
import CreateWalletModal from '../omg-create-wallet-modal'
import CreateTransactionButton from '../omg-transaction/CreateTransactionButton'
import { walletColumsKeys } from './constants'
import AdvancedFilter from '../omg-advanced-filter'

const WalletPageContainer = styled.div`
  position: relative;
  flex-direction: column;
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
  td:nth-child(5) {
    width: 20%;
  }
  tbody td:first-child {
    border-bottom: none;
  }
`

const SortableTableContainer = styled.div`
  position: relative;
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
    showFilter: PropTypes.bool,
    match: PropTypes.shape({
      params: PropTypes.shape({
        accountId: PropTypes.string
      })
    })
  }
  static defaultProps = {
    walletQuery: {},
    transferButton: false,
    showFilter: true,
    fetcher: WalletsFetcher,
    title: 'Wallets'
  }

  state = {
    createWalletModalOpen: false,
    advancedFilterModalOpen: false,
    matchAll: [],
    matchAny: []
  }

  renderAdvancedFilterButton = () => {
    return (
      <Button
        key='filter'
        size='small'
        styleType='secondary'
        onClick={() => this.setState({ advancedFilterModalOpen: true })}
      >
        <Icon name='Filter' /><span>Filter</span>
      </Button>
    )
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
  renderCreateWalletButton = () => {
    return (
      <Button
        key='create-wallet'
        styleType='secondary'
        size='small'
        onClick={this.onClickCreateWallet}
      >
        <Icon name='Plus' />
        <span>Create Wallet</span>
      </Button>
    )
  }
  onClickRow = (data, index) => e => {
    this.props.history.push(`/wallets/${data.address}`)
  }

  renderWalletPage = ({
    data: wallets,
    individualLoadingStatus,
    pagination,
    fetch
  }) => {
    const isAccountWalletsPage =
      queryString.parse(this.props.location.search).walletType !== 'user'
    const { accountId } = this.props.match.params

    return (
      <WalletPageContainer>
        <TopNavigation
          divider={this.props.divider}
          title={this.props.title}
          buttons={[
            this.props.showFilter && this.renderAdvancedFilterButton(),
            this.props.transferButton && (
              <CreateTransactionButton key='transfer' />
            ),
            isAccountWalletsPage && accountId && this.renderCreateWalletButton()
          ]}
        />

        <AdvancedFilter
          title='Filter Wallets'
          page='wallets'
          open={this.state.advancedFilterModalOpen}
          onRequestClose={() => this.setState({ advancedFilterModalOpen: false })}
          onFilter={({ matchAll, matchAny }) => this.setState({ matchAll, matchAny })}
        />

        <SortableTableContainer>
          <SortableTable
            rows={wallets.map(wallet => ({ id: wallet.address, ...wallet }))}
            columns={walletColumsKeys}
            loadingStatus={individualLoadingStatus}
            rowRenderer={walletRowRenderer}
            onClickRow={this.props.onClickRow || this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
          />
        </SortableTableContainer>
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
          matchAny: this.state.matchAny,
          matchAll: [
            ...this.state.matchAll,
            ...(!_.isEmpty(this.props.walletQuery) ? this.props.walletQuery.matchAll : [])
          ]
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(WalletPage)
