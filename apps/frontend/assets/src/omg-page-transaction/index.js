import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router'
import queryString from 'query-string'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'

import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button, Icon } from '../omg-uikit'
import AdvancedFilter from '../omg-advanced-filter'
import TransactionsFetcher from '../omg-transaction/transactionsFetcher'
import { openModal } from '../omg-modal/action'
import CreateTransactionButton from '../omg-transaction/CreateTransactionButton'
import TransactionTable from './TransactionTable'

const TransactionPageContainer = styled.div`
  position: relative;
`

class TransactionPage extends Component {
  static propTypes = {
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    history: PropTypes.object,
    divider: PropTypes.bool,
    query: PropTypes.array,
    topNavigation: PropTypes.bool
  }
  static defaultProps = {
    query: [],
    topNavigation: true
  }
  state = {
    advancedFilterModalOpen: false,
    matchAll: [],
    matchAny: []
  }

  onClickAdvancedFilter = () => {
    this.setState({ advancedFilterModalOpen: true })
  }

  onRequestCloseAdvancedFilter = () => {
    this.setState({ advancedFilterModalOpen: false })
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

  onFilter = ({ matchAll, matchAny }) => {
    this.setState({ matchAll, matchAny })
  }

  renderTransactionPage = ({
    data: transactions,
    individualLoadingStatus,
    pagination,
    fetch
  }) => {
    return (
      <TransactionPageContainer>
        {this.props.topNavigation && (
          <TopNavigation
            divider={this.props.divider}
            title={'Transactions'}
            buttons={[
              this.renderAdvancedFilterButton(),
              this.renderExportButton(),
              <CreateTransactionButton key={'create_transaction'} />
            ]}
          />
        )}

        <AdvancedFilter
          title='Filter Transaction'
          page='transaction'
          open={this.state.advancedFilterModalOpen}
          onRequestClose={this.onRequestCloseAdvancedFilter}
          onFilter={(query) => this.onFilter(query, fetch)}
        />

        <TransactionTable
          loadingStatus={individualLoadingStatus}
          pagination={pagination}
          transactions={transactions}
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
          matchAll: this.state.matchAll,
          matchAny: this.state.matchAny,
          ...this.props.query
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default connect(
  null,
  { openModal }
)(withRouter(TransactionPage))
