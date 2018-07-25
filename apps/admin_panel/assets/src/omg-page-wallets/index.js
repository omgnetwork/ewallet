import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import ExportModal from '../omg-export-modal'
import WalletsFetcher from '../omg-wallet/walletsFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
import { selectWallets } from '../omg-wallet/selector'
import Copy from '../omg-copy'
import CreateTransactionModal from '../omg-create-transaction-modal'
const WalletPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  > div {
    flex: 1;
  }
  td:first-child {
    width: 40%;
  }
  td:nth-child(2),
  td:nth-child(3),
  td:nth-child(4) {
    width: 20%;
  }
  tr:hover {
    i[name="Copy"] {
      visibility: visible;
    }
  }
`
const TransferButton = styled(Button)`
    padding-left: 40px;
    padding-right: 40px;
`
const WalletAddressContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i[name="Wallet"] {
    color: ${props => props.theme.colors.BL400};
    margin-right: 5px;
  }
  i[name="Copy"] {
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
class WalletPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
  }
  constructor (props) {
    super(props)
    this.state = {
      transferModalOpen: false
    }
  }

  onClickTransfer = () => {
    this.setState({ transferModalOpen: true })
  }
  onRequestCloseTransferModal = () => {
    this.setState({ transferModalOpen: false })
  }
  renderTransferButton = () => {
    return (
      <TransferButton size='small' onClick={this.onClickTransfer} key={'transfer'}>
        <Icon name='Transaction' /><span>Transfer</span>
      </TransferButton>
    )
  }
  getColumns = wallets => {
    return [
      { key: 'identifier', title: 'TYPE', sort: true },
      { key: 'address', title: 'ADDRESS', sort: true },
      { key: 'owner', title: 'OWNER TYPE', sort: true },
      { key: 'created_at', title: 'CREATED DATE', sort: true }
    ]
  }
  getRow = wallets => {
    // WALLET API DOESN'T HAVE SEACH TERM, SO WE FILTER AGAIN
    return selectWallets(
      {
        wallets: wallets.map(wallet => {
          return {
            owner: wallet.user_id ? 'User' : 'Account',
            id: wallet.address,
            ...wallet
          }
        })
      },
      queryString.parse(this.props.location.search).search
    )
  }
  onClickRow = (data, index) => e => {
    const { params } = this.props.match
    this.props.history.push(`/${params.accountId}/wallet/${data.address}`)
  }
  rowRenderer (key, data, rows) {
    if (key === 'created_at') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    if (key === 'identifier') {
      return (
        <WalletAddressContainer>
          <Icon name='Wallet' /> <span>{data}</span>
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
  renderWalletPage = ({ data: wallets, individualLoadingStatus, pagination }) => {
    return (
      <WalletPageContainer>
        <TopNavigation title={'Wallets'} buttons={[this.renderTransferButton()]} />
        <SortableTableContainer innerRef={table => (this.table = table)}>
          <SortableTable
            rows={this.getRow(wallets)}
            columns={this.getColumns(wallets)}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            onClickRow={this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
            onClickLoadMore={this.onClickLoadMore}
          />
        </SortableTableContainer>
        <CreateTransactionModal
          open={this.state.transferModalOpen}
          onRequestClose={this.onRequestCloseTransferModal}
        />
      </WalletPageContainer>
    )
  }

  render () {
    return (
      <WalletsFetcher
        {...this.state}
        {...this.props}
        accountId={this.props.match.params.accountId}
        render={this.renderWalletPage}
        query={{
          page: queryString.parse(this.props.location.search).page,
          perPage: 15,
          search: queryString.parse(this.props.location.search).search
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(WalletPage)
