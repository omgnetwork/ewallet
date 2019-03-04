import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import CreateTransactionRequestModal from '../omg-create-transaction-request-modal'
import ExportModal from '../omg-export-modal'
import TransactionRequestsFetcher from '../omg-transaction-request/transactionRequestsFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import Copy from '../omg-copy'
const TransactionRequestsPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  padding-bottom: 50px;
  > div {
    flex: 1;
  }
  td {
    white-space: nowrap;
  }
  td:nth-child(2),
  td:nth-child(7) {
    text-transform: capitalize;
  }
  tr:hover {
    td:nth-child(1) {
      i {
        visibility: visible;
      }
    }
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
const SortableTableContainer = styled.div`
  position: relative;
`
export const NameColumn = styled.div`
  > span {
    margin-left: 10px;
  }
  i[name='Request'] {
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
  }
`
class TransactionRequestsPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    query: PropTypes.object,
    createTransactionRequestButton: PropTypes.bool
  }
  static defaultProps = {
    query: {},
    createTransactionRequestButton: false
  }
  constructor (props) {
    super(props)
    this.state = {
      createTransactionRequestModalOpen:
        queryString.parse(this.props.location.search).createRequest || false,
      exportModalOpen: false
    }
    this.columns = [
      { key: 'id', title: 'REQUEST ID', sort: true },
      { key: 'type', title: 'TYPE', sort: true },
      { key: 'amount', title: 'AMOUNT', sort: true },
      { key: 'created_by', title: 'CREATED BY' },
      { key: 'created_at', title: 'CREATED DATE', sort: true },
      { key: 'require_confirmation', title: 'CONFIRMATION' },
      { key: 'status', title: 'STATUS' }
    ]
  }
  onClickCreateRequest = e => {
    this.setState({ createTransactionRequestModalOpen: true })
  }
  onRequestClose = () => {
    this.setState({ createTransactionRequestModalOpen: false })
  }
  renderCreateTransactionRequestButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateRequest} key={'create'}>
        <Icon name='Plus' /> <span>Create Request</span>
      </Button>
    )
  }
  onClickRow = (data, index) => e => {
    const searchObject = queryString.parse(this.props.location.search)
    this.props.history.push({
      search: queryString.stringify({
        ...searchObject,
        'show-request-tab': data.id
      })
    })
  }
  rowRenderer (key, data, rows) {
    if (key === 'require_confirmation') {
      return data ? 'Yes' : 'No'
    }
    if (key === 'id') {
      return (
        <NameColumn>
          <Icon name='Request' />
          <span>{data}</span> <Copy data={data} />
        </NameColumn>
      )
    }
    if (key === 'amount') {
      const amount =
        rows.amount === null ? (
          'Not Specified'
        ) : (
          <span>
            {formatReceiveAmountToTotal(data, _.get(rows, 'token.subunit_to_unit'))}{' '}
            {_.get(rows, 'token.symbol')}
          </span>
        )
      return amount
    }
    if (key === 'created_by') {
      return rows.user_id || rows.account.name || rows.account_id
    }
    if (key === 'created_at') {
      return moment(data).format()
    }
    if (key === 'updated_at') {
      return moment(data).format()
    }
    return data
  }

  renderTransactionRequestsPage = ({
    data: transactionRequests,
    individualLoadingStatus,
    pagination,
    fetch
  }) => {
    const activeIndexKey = queryString.parse(this.props.location.search)['show-request-tab']
    return (
      <TransactionRequestsPageContainer>
        <TopNavigation
          title={'Transaction Requests'}
          buttons={
            this.props.createTransactionRequestButton
              ? [this.renderCreateTransactionRequestButton()]
              : null
          }
        />
        <SortableTableContainer
          innerRef={table => (this.table = table)}
          loadingStatus={individualLoadingStatus}
        >
          <SortableTable
            rows={transactionRequests}
            columns={this.columns}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            onClickRow={this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
            activeIndexKey={activeIndexKey}
          />
        </SortableTableContainer>
        <CreateTransactionRequestModal
          open={this.state.createTransactionRequestModalOpen}
          onRequestClose={this.onRequestClose}
          onCreateTransactionRequest={fetch}
        />
        <ExportModal open={this.state.exportModalOpen} onRequestClose={this.onRequestCloseExport} />
      </TransactionRequestsPageContainer>
    )
  }

  render () {
    return (
      <TransactionRequestsFetcher
        render={this.renderTransactionRequestsPage}
        {...this.state}
        {...this.props}
        query={{
          page: queryString.parse(this.props.location.search).page,
          perPage: Math.floor(window.innerHeight / 65),
          search: queryString.parse(this.props.location.search).search,
          ...this.props.query
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(TransactionRequestsPage)
