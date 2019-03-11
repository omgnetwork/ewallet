import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import AdminsFetcher from '../omg-admins/adminsFetcher'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
import Copy from '../omg-copy'
import { createSearchAdminsQuery } from '../omg-admins/searchField'

const AdminPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  padding-bottom: 100px;
  > div {
    flex: 1;
  }
  td:first-child {
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
      border-bottom: 1px solid ${props => props.theme.colors.S200};
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
  i[name='Profile'] {
    margin-right: 5px;
    color: ${props => props.theme.colors.B100};
    padding: 8px;
    border-radius: 6px;
    border: 1px solid ${props => props.theme.colors.S400};
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
`
class UsersPage extends Component {
  static propTypes = {
    location: PropTypes.object,
    history: PropTypes.object,
    match: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    query: PropTypes.object,
    fetcher: PropTypes.func,
    navigation: PropTypes.object,
    onClickRow: PropTypes.func,
    columns: PropTypes.array
  }
  static defaultProps = {
    query: {},
    fetcher: AdminsFetcher,
    columns: [
      { key: 'id', title: 'ADMIN ID', sort: true },
      { key: 'email', title: 'EMAIL', sort: true },
      { key: 'created_at', title: 'CREATED DATE', sort: true },
      { key: 'updated_at', title: 'LAST UPDATED', sort: true }
    ]
  }
  constructor (props) {
    super(props)
    this.state = {
      createAccountModalOpen: false
    }
  }
  onClickRow = (data, index) => e => {
    this.props.history.push(`/admins/${data.id}`)
  }
  renderCreateAccountButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateAccount} key={'create'}>
        <Icon name='Plus' /> <span>Create Account</span>
      </Button>
    )
  }
  getRow = admins => {
    return admins.map(d => {
      return {
        ...d,
        avatar: _.get(d, 'avatar.thumb')
      }
    })
  }
  rowRenderer (key, data, rows) {
    switch (key) {
      case 'created_at':
        return moment(data).format()
      case 'updated_at':
        return moment(data).format()
      case 'id':
        return (
          <UserIdContainer>
            <Icon name='Profile' /> <span>{data}</span> <Copy data={data} />
          </UserIdContainer>
        )
      case 'email':
        return data || '-'
      default:
        return data
    }
  }

  renderAdminPage = ({ data: admins, individualLoadingStatus, pagination }) => {
    return (
      <AdminPageContainer>
        <TopNavigation title={'Admins'} />
        <SortableTableContainer innerRef={table => (this.table = table)}>
          <SortableTable
            rows={this.getRow(admins)}
            columns={this.props.columns}
            loadingStatus={individualLoadingStatus}
            rowRenderer={this.rowRenderer}
            onClickRow={this.props.onClickRow || this.onClickRow}
            isFirstPage={pagination.is_first_page}
            isLastPage={pagination.is_last_page}
            navigation={this.props.navigation}
            pagination={false}
          />
        </SortableTableContainer>
      </AdminPageContainer>
    )
  }

  render () {
    const Fetcher = this.props.fetcher
    return (
      <Fetcher
        {...this.state}
        {...this.props}
        render={this.renderAdminPage}
        query={{
          page: queryString.parse(this.props.location.search).page,
          ...createSearchAdminsQuery(queryString.parse(this.props.location.search).search),
          ...this.props.query
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(UsersPage)
