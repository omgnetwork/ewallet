import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon, Avatar } from '../omg-uikit'
import Copy from '../omg-copy'
import CreateAccountModal from '../omg-create-account-modal'
import ExportModal from '../omg-export-modal'
import AccountsFetcher from '../omg-account/accountsFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
const AccountPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  padding-bottom: 50px;
  > div {
    flex: 1;
  }
  td:first-child {
    width: 30%;
    max-width: 30%;
  }
  td:nth-child(2),
  td:nth-child(3) {
    width: 25%;
  }
  td {
    white-space: nowrap;
  }
  tr:hover {
    td:nth-child(2) {
      i {
        visibility: visible;
      }
    }
  }
  i[name="Copy"] {
    margin-left: 5px;
    cursor: pointer;
    visibility: hidden;
    cursor: pointer;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B300};
    }
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
class AccountPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
  }
  constructor (props) {
    super(props)
    this.state = {
      createAccountModalOpen: queryString.parse(props.location.search).createAccount || false,
      exportModalOpen: false,
      loadMoreTime: 1
    }
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
  onClickLoadMore = e => {
    this.setState(({ loadMoreTime }) => ({ loadMoreTime: loadMoreTime + 1 }))
  }
  renderExportButton = () => {
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
  getColumns = accounts => {
    return [
      { key: 'name', title: 'NAME', sort: true },
      { key: 'id', title: 'ID', sort: true },
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
          <Avatar image={rows.avatar} name={data.slice(0, 2)} /> <span>{data}</span>
        </NameColumn>
      )
    }
    if (key === 'id') {
      return (
        <span>
          <span>{data}</span> <Copy data={data} />
        </span>
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
  renderAccountPage = ({ data: accounts, individualLoadingStatus, pagination, fetch }) => {
    return (
      <AccountPageContainer>
        <TopNavigation title={'Account'} buttons={[this.renderCreateAccountButton()]} />
        <SortableTableContainer
          innerRef={table => (this.table = table)}
          loadingStatus={individualLoadingStatus}
        >
          <SortableTable
            rows={this.getRow(accounts)}
            columns={this.getColumns(accounts)}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            onClickRow={this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
          />
        </SortableTableContainer>
        <CreateAccountModal
          open={this.state.createAccountModalOpen}
          onRequestClose={this.onRequestCloseCreateAccount}
          onCreateAccount={fetch}
        />
        <ExportModal open={this.state.exportModalOpen} onRequestClose={this.onRequestCloseExport} />
      </AccountPageContainer>
    )
  }

  render () {
    return (
      <AccountsFetcher
        render={this.renderAccountPage}
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

export default withRouter(AccountPage)
