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
const WalletPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  > div {
    flex: 1;
  }
  /* th:first-child, td:first-child {
    width: 200px;
    max-width: 200px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  } */
`
const SortableTableContainer = styled.div`
  position: relative;
`
class WalletPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object
  }
  constructor (props) {
    super(props)
    this.state = {
      createAccountModalOpen: false,
      exportModalOpen: false,
      loadMoreTime: 1
    }
  }

  componentWillReceiveProps = nextProps => {
    const search = queryString.parse(this.props.location.search).search
    const nextSearch = queryString.parse(nextProps.location.search).search
    if (search !== nextSearch) {
      this.setState({ loadMoreTime: 1 })
    }
  }

  onClickExport = () => {
    this.setState({ exportModalOpen: true })
  }
  onClickLoadMore = e => {
    this.setState(({ loadMoreTime }) => ({ loadMoreTime: loadMoreTime + 1 }))
  }

  onRequestCloseExport = () => {
    this.setState({ exportModalOpen: false })
  }
  renderExportButton = () => {
    return (
      <Button size='small' styleType='ghost' onClick={this.onClickExport} key={'export'}>
        <Icon name='Export' />
        <span>Export</span>
      </Button>
    )
  }
  renderCreateAccountButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateAccount} key={'create'}>
        <Icon name='Plus' /> <span>Create Account</span>
      </Button>
    )
  }
  getColumns = wallets => {
    return [
      { key: 'address', title: 'ADDRESS', sort: true },
      { key: 'owner', title: 'OWNER TYPE', sort: true },
      { key: 'identifier', title: 'TYPE', sort: true },
      { key: 'created_at', title: 'CREATED DATE', sort: true }
    ]
  }
  getRow = wallets => {
    return wallets.map(wallet => {
      return {
        owner: wallet.user_id ? 'User' : 'Account',
        id: wallet.address,
        ...wallet
      }
    })
  }
  onClickRow = (data, index) => e => {
    const { params } = this.props.match
    this.props.history.push(`/${params.accountId}/wallet/${data.address}`)
  }
  rowRenderer (key, data, rows) {
    if (key === 'created_at') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    return data
  }
  renderWalletPage = ({ data: wallets, individualLoadingStatus, pagination }) => {
    return (
      <WalletPageContainer>
        <TopNavigation title={'Wallets'} />
        <SortableTableContainer innerRef={table => (this.table = table)}>
          <SortableTable
            rows={this.getRow(wallets)}
            columns={this.getColumns(wallets)}
            loading={individualLoadingStatus === 'DEFAULT' || individualLoadingStatus === 'INITIATED'}
            rowRenderer={this.rowRenderer}
            onClickRow={this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
            onClickLoadMore={this.onClickLoadMore}
          />
        </SortableTableContainer>
        <ExportModal open={this.state.exportModalOpen} onRequestClose={this.onRequestCloseExport} />
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
          page: this.state.loadMoreTime,
          perPage: 15,
          search: queryString.parse(this.props.location.search).search
        }}
      />
    )
  }
}

export default withRouter(WalletPage)
