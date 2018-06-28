import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon, Avatar } from '../omg-uikit'
import CreateTransactionRequestModal from '../omg-create-transaction-request-modal'
import ExportModal from '../omg-export-modal'
import TransactionRequestsFetcher from '../omg-transaction-request/transactionRequestsFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
const TransactionRequestsPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  padding-bottom: 50px;
  > div {
    flex: 1;
  }
  td:first-child {
    width: 50%;
  }
  td:nth-child(2),
  td:nth-child(3) {
    width: 25%;
  }
`
const SortableTableContainer = styled.div`
  position: relative;
`
export const NameColumn = styled.div`
  > span {
    margin-left: 10px;
  }
`
class TransactionRequestsPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
  }
  constructor (props) {
    super(props)
    this.state = {
      createTransactionRequestModalOpen: false,
      exportModalOpen: false,
      loadMoreTime: 1
    }
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
  getColumns = accounts => {
    return [
      { key: 'name', title: 'NAME', sort: true },
      { key: 'description', title: 'DESCRIPTION', sort: true },
      { key: 'created_at', title: 'CREATED DATE', sort: true },
      { key: 'avatar', title: 'AVATAR', hide: true }
    ]
  }
  getRow = accounts => {
    return accounts.map(d => {
      return {
        ...d,
        avatar: _.get(d, 'avatar.thumb'),
        key: d.id
      }
    })
  }
  onClickRow = (data, index) => e => {
    const { params } = this.props.match
    this.props.history.push(`/${params.accountId}/account/${data.id}`)
  }
  rowRenderer (key, data, rows) {
    if (key === 'name') {
      return (
        <NameColumn>
          <Avatar image={rows.avatar} /> <span>{data}</span>
        </NameColumn>
      )
    }
    if (key === 'created_at') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    if (key === 'updated_at') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    if (key === 'avatar') {
      return null
    }
    return data
  }
  renderTransactionRequestsPage = ({
    data: transactionRequests,
    individualLoadingStatus,
    pagination,
    fetch
  }) => {
    return (
      <TransactionRequestsPageContainer>
        <TopNavigation
          title={'Transaction Requests'}
          buttons={[this.renderCreateTransactionRequestButton()]}
        />
        <SortableTableContainer
          innerRef={table => (this.table = table)}
          loadingStatus={individualLoadingStatus}
        >
          <SortableTable
            rows={this.getRow(transactionRequests)}
            columns={this.getColumns(transactionRequests)}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            onClickRow={this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
            onClickLoadMore={this.onClickLoadMore}
          />
        </SortableTableContainer>
        <CreateTransactionRequestModal
          open={this.state.createTransactionRequestModalOpen}
          onRequestClose={this.onRequestClose}
          onCreateAccount={fetch}
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
          search: queryString.parse(this.props.location.search).search
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(TransactionRequestsPage)
