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
`
const columns = [
  { key: 'id', title: 'TRANSACTION ID' },
  { key: 'toFrom', title: 'FROM/TO' },
  {
    key: 'fromToToken',
    title: 'EXCHANGE'
  },
  {
    key: 'created_at',
    title: 'TIMESTAMP',
    sort: true
  },
  { key: 'status', title: 'STATUS', sort: true }
]

class TransactionPage extends Component {
  static propTypes = {
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
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
  onClickExport = () => {
    this.setState({ exportModalOpen: true })
  }
  onRequestCloseExport = () => {
    this.setState({ exportModalOpen: false })
  }

  renderCreateTransactionButton = () => {
    return (
      <Button size='small' styleType='primary' onClick={this.onClickCreateTransaction} key={'create'}>
        <Icon name='Export' />
        <span>Create Transaction</span>
      </Button>
    )
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'toFrom') {
      return (
        <div>
          {rows.from.address}
          <br /> {rows.to.address}
        </div>
      )
    }
    if (key === 'fromToToken') {
      return (
        <div>
          <div>
            - {(rows.from.amount / rows.from.token.subunit_to_unit).toLocaleString()}{' '}
            {rows.from.token.symbol}
          </div>
          <div>
            + {(rows.to.amount / rows.from.token.subunit_to_unit).toLocaleString()}{' '}
            {rows.to.token.symbol}
          </div>
        </div>
      )
    }
    if (key === 'created_at') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    return data
  }
  renderTransactionPage = ({ transactions, loadingStatus, pagination }) => {
    return (
      <TransactionPageContainer>
        <TopNavigation title={'Transaction'} buttons={[this.renderCreateTransactionButton()]} />
        <SortableTable
          rows={transactions.map(t => ({ ...t, id: t.id }))}
          columns={columns}
          rowRenderer={this.rowRenderer}
          perPage={15}
          loading={loadingStatus === 'DEFAULT' || loadingStatus === 'INITIATED'}
          isFirstPage={pagination.is_first_page}
          isLastPage={pagination.is_last_page}
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
        search={queryString.parse(this.props.location.search).search}
        perPage={15}
        page={Number(queryString.parse(this.props.location.search).page || 1)}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(TransactionPage)
