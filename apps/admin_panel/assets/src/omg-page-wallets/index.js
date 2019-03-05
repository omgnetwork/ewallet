import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import WalletsFetcher from '../omg-wallet/allWalletsFetcher'
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
  td:nth-child(1) {
    width: 40%;
    border: none;
    position: relative;
    :before {
      content: '';
      position: absolute;
      right: 0;
      bottom: -1px;
      height: 1px;
      width: calc(100% - 50px);
      border-bottom: 1px solid ${props => props.theme.colors.S100};
    }
  }
  td:nth-child(2),
  td:nth-child(3),
  td:nth-child(4) {
    width: 20%;
  }
  tbody td:first-child {
    border-bottom: none;
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
  i[name='Wallet'] {
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
    margin-right: 5px;
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
class WalletPage extends Component {
  static propTypes = {
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    walletQuery: PropTypes.object,
    transferButton: PropTypes.bool,
    onClickRow: PropTypes.func,
    fetcher: PropTypes.func
  }
  static defaultProps = {
    walletQuery: {},
    transferButton: false,
    fetcher: WalletsFetcher
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
        <Icon name='Transaction' />
        <span>Transfer</span>
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
    this.props.history.push(`/wallets/${data.address}`)
  }
  rowRenderer (key, data, rows) {
    if (key === 'created_at') {
      return moment(data).format()
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
        <TopNavigation
          title={'Wallets'}
          buttons={[this.props.transferButton && this.renderTransferButton()]}
        />
        <SortableTableContainer innerRef={table => (this.table = table)}>
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
          perPage: 15,
          search: queryString.parse(this.props.location.search).search,
          ...this.props.walletQuery
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(WalletPage)
