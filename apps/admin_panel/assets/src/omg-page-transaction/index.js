import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import CreateTransactionModal from '../omg-create-transaction-modal'
import TransactionsFetcher from '../omg-transaction/transactionsFetcher'
import { withRouter } from 'react-router'
import moment from 'moment'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import { formatReceiveAmountToTotal } from '../utils/formatter'
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
  td:nth-child(1) {
    width: 30%;
  }
  td:nth-child(3) {
    width: 20%;
  }
  table {
    td {
      vertical-align: top;
    }
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
  }
`
const TransferButton = styled(Button)`
  padding-left: 40px;
  padding-right: 40px;
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
    scrollTopContentContainer: PropTypes.func,
    history: PropTypes.object
  }
  state = {
    createTransactionModalOpen: false
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
        [`show-transaction-tab`]: data.id
      })
    })
  }
  renderCreateTransactionButton = () => {
    return (
      <TransferButton
        size='small'
        styleType='primary'
        onClick={this.onClickCreateTransaction}
        key={'create'}
      >
        <Icon name='Transaction' />
        <span>Transfer</span>
      </TransferButton>
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
          {data === 'failed' ? (
            <MarkContainer status='failed'>
              <Icon name='Close' />
            </MarkContainer>
          ) : (
            <MarkContainer status='success'>
              <Icon name='Checked' />
            </MarkContainer>
          )}{' '}
          <span>{data}</span>
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
      return moment(data).format('DD/MM/YYYY hh:mm:ss')
    }
    return data
  }
  renderTransactionPage = ({ data: transactions, individualLoadingStatus, pagination, fetch }) => {
    return (
      <TransactionPageContainer>
        <TopNavigation title={'Transaction'} buttons={[this.renderCreateTransactionButton()]} />
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
        />

        <CreateTransactionModal
          onRequestClose={this.onRequestCloseCreateTransaction}
          open={this.state.createTransactionModalOpen}
          onCreateTransaction={fetch}
        />
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
          page: queryString.parse(this.props.location.search).page,
          perPage: 15,
          search: queryString.parse(this.props.location.search).search
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(TransactionPage)
