import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import CreateTransactionModal from '../omg-create-transaction-modal'
import ExportModal from '../omg-export-modal'
import TransactionsFetcher from '../omg-transaction/transactionsFetcher'
import { withRouter } from 'react-router'
import moment from 'moment'
import queryString from 'query-string'
import PropTypes from 'prop-types'
const TransactionPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  padding-bottom: 50px;
  > div {
    flex: 1;
  }
  td:nth-child(2) {
    white-space: nowrap;
    > div {
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }
  td:nth-child(3) {
    width: 20%;
  }
`
const TransactionIdContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i {
    color: ${props => props.theme.colors.BL400};
    margin-right: 5px;
  }
`
const StatusContainer = TransactionIdContainer.extend`
  i[name=Close] {
    color: red;
  }
  i[name=Checkmark] {
    color: green;
  }
`
const Sign = styled.span`
  width: 10px;
  display: inline-block;
`
const FromToContainer = styled.div`
  > div:first-child {
    white-space: nowrap;
    margin-bottom: 5px;
  }
`
const columns = [
  { key: 'id', title: 'TRANSACTION ID' },
  { key: 'toFrom', title: 'FROM/TO' },
  {
    key: 'fromToToken',
    title: 'EXCHANGE'
  },
  { key: 'status', title: 'STATUS', sort: true },
  {
    key: 'created_at',
    title: 'TIMESTAMP',
    sort: true
  }
]

class TransactionPage extends Component {
  static propTypes = {
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
  }
  state = {
    createTransactionModalOpen: false,
    loadMoreTime: 1
  }
  componentWillReceiveProps = nextProps => {
    const search = queryString.parse(this.props.location.search).search
    const nextSearch = queryString.parse(nextProps.location.search).search
    if (search !== nextSearch) {
      this.setState({ loadMoreTime: 1 })
    }
  }
  onClickCreateTransaction = () => {
    this.setState({ createTransactionModalOpen: true })
  }
  onRequestCloseCreateTransaction = () => {
    this.setState({ createTransactionModalOpen: false })
  }
  onClickExport = () => {
    this.setState({ exportModalOpen: true })
  }
  onRequestCloseExport = () => {
    this.setState({ exportModalOpen: false })
  }
  onClickLoadMore = e => {
    this.setState(({ loadMoreTime }) => ({ loadMoreTime: loadMoreTime + 1 }))
  }
  renderCreateTransactionButton = () => {
    return (
      <Button
        size='small'
        styleType='primary'
        onClick={this.onClickCreateTransaction}
        key={'create'}
      >
        <Icon name='Export' />
        <span>Create Transaction</span>
      </Button>
    )
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'id') {
      return (
        <TransactionIdContainer>
          <Icon name='Transaction' /> <span>{data}</span>
        </TransactionIdContainer>
      )
    }
    if (key === 'status') {
      return (
        <StatusContainer>
          {data === 'failed' ? <Icon name='Close' /> : <Icon name='Checkmark' />} <span>{data}</span>
        </StatusContainer>
      )
    }
    if (key === 'toFrom') {
      return (
        <FromToContainer>
          <div>{rows.from.address}</div>
          <div>{rows.to.address}</div>
        </FromToContainer>
      )
    }
    if (key === 'fromToToken') {
      return (
        <FromToContainer>
          <div>
            <Sign>-</Sign>{(rows.from.amount / rows.from.token.subunit_to_unit).toLocaleString()}{' '}
            {rows.from.token.symbol}
          </div>
          <div>
            <Sign>+</Sign>{(rows.to.amount / rows.from.token.subunit_to_unit).toLocaleString()}{' '}
            {rows.to.token.symbol}
          </div>
        </FromToContainer>
      )
    }
    if (key === 'created_at') {
      return moment(data).format('DD/MM/YYYY hh:mm:ss')
    }
    return data
  }
  renderTransactionPage = ({ data: transactions, individualLoadingStatus, pagination }) => {
    return (
      <TransactionPageContainer>
        <TopNavigation title={'Transaction'} buttons={[this.renderCreateTransactionButton()]} />
        <SortableTable
          rows={transactions.map(t => ({ ...t, id: t.id }))}
          columns={columns}
          rowRenderer={this.rowRenderer}
          perPage={15}
          loading={individualLoadingStatus === 'DEFAULT' || individualLoadingStatus === 'INITIATED'}
          isFirstPage={pagination.is_first_page}
          isLastPage={pagination.is_last_page}
          navigation
          onClickLoadMore={this.onClickLoadMore}
        />

        <CreateTransactionModal
          onRequestClose={this.onRequestCloseCreateTransaction}
          open={this.state.createTransactionModalOpen}
        />
        <ExportModal open={this.state.exportModalOpen} onRequestClose={this.onRequestCloseExport} />
      </TransactionPageContainer>
    )
  }
  render () {
    return (
      <TransactionsFetcher
        {...this.state}
        {...this.props}
        render={this.renderTransactionPage}
        query={{
          page: this.state.loadMoreTime,
          perPage: 15,
          search: queryString.parse(this.props.location.search).search
        }}
      />
    )
  }
}

export default withRouter(TransactionPage)
