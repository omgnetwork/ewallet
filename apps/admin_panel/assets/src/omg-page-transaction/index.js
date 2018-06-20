import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import CreateAccountModal from '../omg-create-account-modal'
import ExportModal from '../omg-export-modal'
import TransactionsProvider from '../omg-transaction/transactionsProvider'
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
    location: PropTypes.object
  }
  state = {
    createAccountModalOpen: false
  }
  onClickCreateAccount = () => {
    this.setState({ createAccountModalOpen: true })
  }
  onRequestCloseCreateAccount = () => {
    this.setState({ createAccountModalOpen: false })
  }
  onClickExport = () => {
    this.setState({ exportModalOpen: true })
  }
  onRequestCloseExport = () => {
    this.setState({ exportModalOpen: false })
  }

  renderCreateTransactionButton = () => {
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
  renderTransactionPage = ({ transactions, loadingStatus }) => {
    return (
      <TransactionPageContainer>
        <TopNavigation title={'Transaction'} buttons={[this.renderCreateTransactionButton()]} />
        <SortableTable
          dataSource={transactions}
          columns={columns}
          rowRenderer={this.rowRenderer}
          loading={loadingStatus === 'DEFAULT' || loadingStatus === 'INITIATED'}
        />
        <CreateAccountModal
          open={this.state.createAccountModalOpen}
          onRequestClose={this.onRequestCloseCreateAccount}
        />
        <ExportModal open={this.state.exportModalOpen} onRequestClose={this.onRequestCloseExport} />
      </TransactionPageContainer>
    )
  }
  render () {
    return (
      <TransactionsProvider
        render={this.renderTransactionPage}
        {...this.state}
        {...this.props}
        search={queryString.parse(this.props.location.search).search}
      />
    )
  }
}

export default withRouter(TransactionPage)
