import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon } from '../omg-uikit'
import ExportModal from '../omg-export-modal'
import UsersProvider from '../omg-users/usersProvider'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
const UserPageContainer = styled.div`
  position: relative;
  display: flex;
  flex-direction: column;
  padding-bottom: 100px;
  > div {
    flex: 1;
  }
  th:first-child {
    width: 50%;
  }
`
const SortableTableContainer = styled.div`
  position: relative;
  td {
    white-space: nowrap;
  }
`
class UsersPage extends Component {
  static propTypes = {
    location: PropTypes.object,
    history: PropTypes.object,
    match: PropTypes.object
  }
  constructor (props) {
    super(props)
    this.state = {
      createAccountModalOpen: false,
      exportModalOpen: false
    }
  }
  onClickExport = () => {
    this.setState({ exportModalOpen: true })
  }
  onRequestCloseExport = () => {
    this.setState({ exportModalOpen: false })
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
      { key: 'username', title: 'USERNAME', sort: true },
      { key: 'email', title: 'EMAIL', sort: true },
      { key: 'created_at', title: 'CREATED DATE', sort: true },
      { key: 'provider_user_id', title: 'PROVIDER', sort: true }
    ]
  }
  getRow = users => {
    return users.map(d => {
      return {
        ...d,
        avatar: d.avatar.thumb
      }
    })
  }
  rowRenderer (key, data, rows) {
    if (key === 'created_at') {
      return moment(data).format('ddd, DD/MM/YYYY hh:mm:ss')
    }
    return data
  }
  onClickRow = (data, index) => e => {
    const { params } = this.props.match
    this.props.history.push(`/${params.accountId}/user/${data.id}`)
  }
  renderUserPage = ({ users, loadingStatus }) => {
    return (
      <UserPageContainer>
        <TopNavigation
          title={'Users'}
          // buttons={[this.renderExportButton()]}
        />
        <SortableTableContainer innerRef={table => (this.table = table)}>
          <SortableTable
            rows={this.getRow(users)}
            columns={this.getColumns(users)}
            loading={loadingStatus === 'DEFAULT' || loadingStatus === 'INITIATED'}
            rowRenderer={this.rowRenderer}
            onClickRow={this.onClickRow}
            perPage={20}
          />
        </SortableTableContainer>
        <ExportModal open={this.state.exportModalOpen} onRequestClose={this.onRequestCloseExport} />
      </UserPageContainer>
    )
  }

  render () {
    return (
      <UsersProvider
        render={this.renderUserPage}
        {...this.state}
        {...this.props}
        search={queryString.parse(this.props.location.search).search}
        perPage={20}
        page={queryString.parse(this.props.location.search).page}
      />
    )
  }
}

export default withRouter(UsersPage)
