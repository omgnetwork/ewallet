import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import ExportModal from '../omg-export-modal'
import UsersFetcher from '../omg-users/usersFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
import Copy from '../omg-copy'
import { createSearchUsersQuery } from '../omg-users/searchField'
const UserPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  padding-bottom: 100px;
  > div {
    flex: 1;
  }
  td:first-child {
    width: 40%;
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
const SortableTableContainer = styled.div`
  position: relative;
  td {
    white-space: nowrap;
  }
`
const UserIdContainer = styled.div`
  white-space: nowrap;
  span {
    vertical-align: middle;
  }
  i {
    margin-right: 5px;
    color: ${props => props.theme.colors.BL400};
  }
`
class UsersPage extends Component {
  static propTypes = {
    location: PropTypes.object,
    history: PropTypes.object,
    match: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
  }
  constructor (props) {
    super(props)
    this.state = {
      createAccountModalOpen: false,
      exportModalOpen: false
    }
  }
  onClickRow = (data, index) => e => {
    const { params } = this.props.match
    this.props.history.push(`/${params.accountId}/users/${data.id}`)
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
  getColumns = () => {
    return [
      { key: 'id', title: 'ID', sort: true },
      { key: 'email', title: 'EMAIL', sort: true },
      { key: 'username', title: 'USERNAME', sort: true },
      { key: 'created_at', title: 'CREATED DATE', sort: true },
      { key: 'updated_at', title: 'LAST UPDATED', sort: true },
      { key: 'provider_user_id', title: 'PROVIDER', sort: true }
    ]
  }
  getRow = users => {
    return users.map(d => {
      return {
        ...d,
        avatar: _.get(d, 'avatar.thumb')
      }
    })
  }
  rowRenderer (key, data, rows) {
    if (key === 'created_at' || key === 'updated_at') {
      return moment(data).format('ddd, DD/MM/YYYY HH:mm:ss')
    }
    if (key === 'id') {
      return (
        <UserIdContainer>
          <Icon name='Profile' /> <span>{data}</span> <Copy data={data} />
        </UserIdContainer>
      )
    }
    if (key === 'email') {
      return data || '-'
    }

    return data
  }

  renderUserPage = ({ data: users, individualLoadingStatus, pagination }) => {
    return (
      <UserPageContainer>
        <TopNavigation title={'Users'} />
        <SortableTableContainer innerRef={table => (this.table = table)}>
          <SortableTable
            rows={this.getRow(users)}
            columns={this.getColumns(users)}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            onClickRow={this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation
            pagination={false}
          />
        </SortableTableContainer>
        <ExportModal open={this.state.exportModalOpen} onRequestClose={this.onRequestCloseExport} />
      </UserPageContainer>
    )
  }

  render () {
    return (
      <UsersFetcher
        {...this.state}
        {...this.props}
        render={this.renderUserPage}
        query={{
          page: queryString.parse(this.props.location.search).page,
          perPage: 15,
          accountId: this.props.match.params.accountId,
          ...createSearchUsersQuery(queryString.parse(this.props.location.search).search)
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(UsersPage)
