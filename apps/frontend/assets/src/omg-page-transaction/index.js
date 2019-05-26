import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import TopNavigation from '../omg-page-layout/TopNavigation'
import SortableTable from '../omg-table'
import { Button } from '../omg-uikit'
import TransactionsFetcher from '../omg-transaction/transactionsFetcher'
import { openModal } from '../omg-modal/action'
import { connect } from 'react-redux'
import { tableColumsKeys } from './constants'
import { selectNewTransactions } from '../omg-transaction/selector'
import CreateTransactionButton from '../omg-transaction/CreateTransactionButton'
import rowRenderer from './transactionTableRowRenderer'
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

class TransactionPage extends Component {
  static propTypes = {
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    history: PropTypes.object,
    divider: PropTypes.bool,
    query: PropTypes.object,
    topNavigation: PropTypes.bool,
    newTransactions: PropTypes.array
  }
  static defaultProps = {
    query: {},
    topNavigation: true
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

  renderExportButton () {
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
  renderTransactionPage = ({
    data: transactions,
    individualLoadingStatus,
    pagination,
    fetch
  }) => {
    const query = queryString.parse(this.props.location.search)
    const activeIndexKey = query['show-transaction-tab']
    return (
      <TransactionPageContainer>
        {this.props.topNavigation && (
          <TopNavigation
            divider={this.props.divider}
            title={'Transactions'}
            buttons={[
              this.renderExportButton(),
              <CreateTransactionButton key={'create_transaction'} />
            ]}
          />
        )}
        <SortableTable
          rows={[...this.props.newTransactions, ...transactions]}
          columns={tableColumsKeys}
          rowRenderer={rowRenderer}
          perPage={15}
          loadingStatus={individualLoadingStatus}
          isFirstPage={pagination.is_first_page}
          isLastPage={pagination.is_last_page}
          navigation
          onClickRow={this.onClickRow}
          activeIndexKey={activeIndexKey}
        />
      </TransactionPageContainer>
    )
  }
  render () {
    return (
      <TransactionsFetcher
        render={this.renderTransactionPage}
        query={{
          page: queryString.parse(this.props.location.search).page,
          perPage: Math.floor(window.innerHeight / 100),
          search: queryString.parse(this.props.location.search).search,
          ...this.props.query
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default connect(
  state => ({ newTransactions: selectNewTransactions(state) }),
  { openModal }
)(withRouter(TransactionPage))
