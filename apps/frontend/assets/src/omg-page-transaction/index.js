import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router'
import queryString from 'query-string'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { Button } from '../omg-uikit'
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
    query: PropTypes.object,
    topNavigation: PropTypes.bool
  }
  static defaultProps = {
    query: {},
    topNavigation: true
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
    pagination
  }) => {
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
