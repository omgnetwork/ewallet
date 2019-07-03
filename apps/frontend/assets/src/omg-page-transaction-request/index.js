import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'

import TopNavigation from '../omg-page-layout/TopNavigation'
import SortableTable from '../omg-table'
import { Button, Icon, Id } from '../omg-uikit'
import CreateTransactionRequestModal from '../omg-create-transaction-request-modal'
import ExportModal from '../omg-export-modal'
import TransactionRequestsFetcher from '../omg-transaction-request/transactionRequestsFetcher'
import { formatReceiveAmountToTotal } from '../utils/formatter'
import AdvancedFilter from '../omg-advanced-filter'

const TransactionRequestsPageContainer = styled.div`
  position: relative;
  padding-bottom: 50px;
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
    border: none;
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
  i[name='Copy'] {
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
const StyledIcon = styled.span`
  i {
    margin-top: -3px;
    margin-right: 10px;
    margin-top
    font-size: 14px;
    font-weight: 400;
  }
`
export const NameColumn = styled.div`
  display: flex;
  flex-direction: row;
  > span {
    margin-left: 10px;
  }
  i[name='Request'] {
    margin-right: 15px;
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
  }
`
class TransactionRequestsPage extends Component {
  static propTypes = {
    divider: PropTypes.bool,
    history: PropTypes.object,
    location: PropTypes.object,
    showFilter: PropTypes.bool,
    scrollTopContentContainer: PropTypes.func,
    query: PropTypes.object,
    createTransactionRequestButton: PropTypes.bool
  }
  static defaultProps = {
    query: {},
    showFilter: true,
    createTransactionRequestButton: true
  }
  constructor (props) {
    super(props)
    this.state = {
      createTransactionRequestModalOpen:
        queryString.parse(this.props.location.search).createRequest || false,
      exportModalOpen: false,
      advancedFilterModalOpen: false,
      matchAll: [],
      matchAny: []
    }
    this.columns = [
      { key: 'id', title: 'REQUEST ID', sort: true },
      { key: 'type', title: 'TYPE', sort: true },
      { key: 'amount', title: 'AMOUNT', sort: true },
      { key: 'require_confirmation', title: 'CONFIRMATION' },
      { key: 'status', title: 'STATUS' },
      { key: 'created_by', title: 'CREATED BY' },
      { key: 'created_at', title: 'CREATED AT', sort: true }
    ]
  }
  onClickCreateRequest = e => {
    this.setState({ createTransactionRequestModalOpen: true })
  }
  onRequestClose = () => {
    this.setState({ createTransactionRequestModalOpen: false })
  }
  renderAdvancedFilterButton = () => {
    return (
      <Button
        key='filter'
        size='small'
        styleType='secondary'
        onClick={() => this.setState({ advancedFilterModalOpen: true })}
      >
        <Icon name='Filter' /><span>Filter</span>
      </Button>
    )
  }
  renderCreateTransactionRequestButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateRequest} key={'create'}>
        <Icon name='Plus' /><span>Create Request</span>
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
  renderCreator = request => {
    return (
      <span>
        {request.account &&
          <span>
            <StyledIcon><Icon name='Merchant' /></StyledIcon>
            {request.account.name}
          </span>

        }
        {request.user && request.user.email &&
          <span>
            <StyledIcon><Icon name='People' /></StyledIcon>
            {request.user.email}
          </span>
        }
        {request.user && request.user.provider_user_id &&
          <span>
            <StyledIcon><Icon name='People' /></StyledIcon>
            {request.user.provider_user_id}
          </span>
        }
      </span>
    )
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'status') {
      return _.upperFirst(data)
    }
    if (key === 'require_confirmation') {
      return data ? 'Yes' : 'No'
    }
    if (key === 'id') {
      return (
        <NameColumn>
          <Icon name='Request' /><Id>{data}</Id>
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
      return this.renderCreator(rows)
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
          divider={this.props.divider}
          title={'Transaction Requests'}
          buttons={[
            this.props.showFilter && this.renderAdvancedFilterButton(),
            this.props.createTransactionRequestButton
              ? this.renderCreateTransactionRequestButton()
              : null
          ]}
        />
        <AdvancedFilter
          title='Filter Transaction Request'
          page='transaction-requests'
          open={this.state.advancedFilterModalOpen}
          onRequestClose={() => this.setState({ advancedFilterModalOpen: false })}
          onFilter={({ matchAll, matchAny }) => this.setState({ matchAll, matchAny })}
        />
        <SortableTableContainer
          ref={table => (this.table = table)}
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
          perPage: 10,
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

export default withRouter(TransactionRequestsPage)
