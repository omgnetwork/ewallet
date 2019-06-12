import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router'
import moment from 'moment'
import queryString from 'query-string'
import PropTypes from 'prop-types'

import TopNavigation from '../omg-page-layout/TopNavigation'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import CreateTransactionModal from '../omg-create-transaction-modal'
import AdvancedFilterModal from '../omg-advanced-filter-modal'
import TransactionsFetcher from '../omg-transaction/transactionsFetcher'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import Copy from '../omg-copy'

const TransactionPageContainer = styled.div`
  position: relative;
  td:nth-child(3) {
    white-space: nowrap;
    > div {
      overflow: hidden;
      text-overflow: ellipsis;
    }
  }
  td:nth-child(1) {
    padding-right: 0;
    border-bottom: none;
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
  table {
    td {
      vertical-align: middle;
    }
  }
  tr:hover {
    td:nth-child(1) {
      i {
        visibility: visible;
      }
    }
  }
  i[name='Copy'] {
    margin-left: 5px;
    cursor: pointer;
    visibility: hidden;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B300};
    }
  }
`
const TransactionIdContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i[name='Transaction'] {
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
    margin-right: 10px;
  }
`
const StatusContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i {
    color: white;
    font-size: 10px;
  }
`
const Sign = styled.span`
  width: 10px;
  display: inline-block;
  vertical-align: middle;
`
const BoldSpan = styled.span`
  font-weight: bold;
`
const FromOrToRow = styled.div`
  white-space: nowrap;
`
const FromToContainer = styled.div`
  > div:first-child {
    white-space: nowrap;
    margin-bottom: 10px;
    span {
      vertical-align: middle;
    }
  }
`
export const MarkContainer = styled.div`
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background-color: ${props => (props.status === 'failed' ? '#FC7166' : '#0EBF9A')};
  display: inline-block;
  text-align: center;
  line-height: 18px;
  margin-right: 5px;
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
    title: 'CREATED AT',
    sort: true
  }
]

class TransactionPage extends Component {
  static propTypes = {
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    history: PropTypes.object,
    divider: PropTypes.bool,
    query: PropTypes.array
  }
  static defaultProps = {
    query: []
  }
  state = {
    createTransactionModalOpen: false,
    advancedFilterModalOpen: false
  }
  onClickAdvancedFilter = () => {
    this.setState({ advancedFilterModalOpen: true })
  }
  onRequestCloseAdvancedFilter = () => {
    this.setState({ advancedFilterModalOpen: false })
  }
  onClickCreateTransaction = () => {
    this.setState({ createTransactionModalOpen: true })
  }
  onRequestCloseCreateTransaction = () => {
    this.setState({ createTransactionModalOpen: false })
  }
  onClickRow = (data, index) => e => {
    const searchObject = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        'show-transaction-tab': data.id
      })
    })
  }
  onClickExport = e => {
    this.props.history.push('/transaction/export')
  }
  renderCreateTransactionButton = () => {
    return (
      <Button
        key='create'
        size='small'
        styleType='primary'
        onClick={this.onClickCreateTransaction}
      >
        <Icon name='Transaction' /><span>Transfer</span>
      </Button>
    )
  }
  renderExportButton = () => {
    return (
      <Button
        key='export'
        size='small'
        styleType='secondary'
        onClick={this.onClickExport}
      >
        <span>Export</span>
      </Button>
    )
  }
  renderAdvancedFilterButton = () => {
    return (
      <Button
        key='filter'
        size='small'
        styleType='secondary'
        onClick={this.onClickAdvancedFilter}
      >
        <Icon name='Filter' /><span>Filter</span>
      </Button>
    )
  }
  renderFromOrTo = (fromOrTo) => {
    return (
      <FromOrToRow>
        {fromOrTo.account && (
          <BoldSpan>{fromOrTo.account.name}</BoldSpan>
        )}
        {fromOrTo.user && fromOrTo.user.email && (
          <BoldSpan>{fromOrTo.user.email}</BoldSpan>
        )}
        {fromOrTo.user && fromOrTo.user.provider_user_id && (
          <BoldSpan>{fromOrTo.user.provider_user_id}</BoldSpan>
        )}
        <span> - {fromOrTo.address}</span>
      </FromOrToRow>
    )
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'id') {
      return (
        <TransactionIdContainer>
          <Icon name='Transaction' />
          <span>{data}</span> <Copy data={data} />
        </TransactionIdContainer>
      )
    }

    if (key === 'status') {
      return (
        <StatusContainer>
          {data === 'failed' ? (
            <MarkContainer status='failed'>
              <Icon name='Close' />
            </MarkContainer>
          ) : (
            <MarkContainer status='success'>
              <Icon name='Checked' />
            </MarkContainer>
          )}{' '}
          <span>{_.capitalize(data)}</span>
        </StatusContainer>
      )
    }
    if (key === 'toFrom') {
      return (
        <FromToContainer>
          <div>{this.renderFromOrTo(rows.from)}</div>
          <div>{this.renderFromOrTo(rows.to)}</div>
        </FromToContainer>
      )
    }
    if (key === 'fromToToken') {
      return (
        <FromToContainer>
          <div>
            <Sign>-</Sign>
            <span>
              {formatReceiveAmountToTotal(rows.from.amount, rows.from.token.subunit_to_unit)}{' '}
              {rows.from.token.symbol}
            </span>
          </div>
          <div>
            <Sign>+</Sign>
            <span>
              {formatReceiveAmountToTotal(rows.to.amount, rows.to.token.subunit_to_unit)}{' '}
              {rows.to.token.symbol}
            </span>
          </div>
        </FromToContainer>
      )
    }
    if (key === 'created_at') {
      return moment(data).format()
    }
    return data
  }
  renderTransactionPage = ({ data: transactions, individualLoadingStatus, pagination, fetch }) => {
    const activeIndexKey = queryString.parse(this.props.location.search)['show-transaction-tab']

    return (
      <TransactionPageContainer>
        <TopNavigation
          divider={this.props.divider}
          title={'Transactions'}
          buttons={[
            this.renderAdvancedFilterButton(),
            this.renderExportButton(),
            this.renderCreateTransactionButton()
          ]}
        />

        {/* TODO: turn filters into deletable tags below topnav */}

        <SortableTable
          rows={transactions}
          columns={columns}
          rowRenderer={this.rowRenderer}
          perPage={15}
          loadingStatus={individualLoadingStatus}
          isFirstPage={pagination.is_first_page}
          isLastPage={pagination.is_last_page}
          navigation
          onClickRow={this.onClickRow}
          activeIndexKey={activeIndexKey}
        />
        <CreateTransactionModal
          onRequestClose={this.onRequestCloseCreateTransaction}
          open={this.state.createTransactionModalOpen}
          onCreateTransaction={fetch}
        />
        <AdvancedFilterModal
          title='Filter Transaction'
          page='transaction'
          open={this.state.advancedFilterModalOpen}
          onRequestClose={this.onRequestCloseAdvancedFilter}
          onFilter={(query) => this.onFilter(query, fetch)}
        />
      </TransactionPageContainer>
    )
  }
  onFilter = (query, fetch) => {
    this.setState({ query })
    // this.setState({ query }, fetch)
  }
  render () {
    return (
      <TransactionsFetcher
        render={this.renderTransactionPage}
        query={{
          page: queryString.parse(this.props.location.search).page,
          perPage: Math.floor(window.innerHeight / 100),
          search: queryString.parse(this.props.location.search).search,
          matchAll: this.state.query,
          ...this.props.query
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(TransactionPage)
