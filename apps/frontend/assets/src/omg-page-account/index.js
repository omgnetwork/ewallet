import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'

import TopNavigation from '../omg-page-layout/TopNavigation'
import SortableTable from '../omg-table'
import { Button, Icon, Avatar, Id } from '../omg-uikit'
import CreateAccountModal from '../omg-create-account-modal'
import ExportModal from '../omg-export-modal'
import AccountsFetcher from '../omg-account/accountsFetcher'

const AccountPageContainer = styled.div`
  position: relative;
  padding-bottom: 50px;
  td:nth-child(1) {
    width: 30%;
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
  i[name='Copy'] {
    cursor: pointer;
    visibility: hidden;
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
    divider: PropTypes.bool,
    history: PropTypes.object,
    location: PropTypes.object,
    scrollTopContentContainer: PropTypes.func
  }
  constructor (props) {
    super(props)
    this.state = {
      createAccountModalOpen: queryString.parse(props.location.search).createAccount || false,
      exportModalOpen: false
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
  renderExportButton = () => {
    return (
      <Button size='small' styleType='ghost' onClick={this.onClickExport} key={'export'}>
        <Icon name='Export' /><span>Export</span>
      </Button>
    )
  }
  renderCreateAccountButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateAccount} key={'create'}>
        <Icon name='Plus' /><span>Create Account</span>
      </Button>
    )
  }
  getColumns = accounts => {
    return [
      { key: 'name', title: 'NAME', sort: true },
      { key: 'id', title: 'ID', sort: true },
      { key: 'description', title: 'DESCRIPTION', sort: true },
      { key: 'created_at', title: 'CREATED AT', sort: true },
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
    this.props.history.push(`/accounts/${data.id}/details`)
  }
  rowRenderer (key, data, rows) {
    if (key === 'name') {
      return (
        <NameColumn>
          <Avatar image={rows.avatar} name={data.slice(0, 3)} /><span>{data}</span>
        </NameColumn>
      )
    }
    if (key === 'id') {
      return <Id>{data}</Id>
    }
    if (key === 'created_at') {
      return moment(data).format()
    }
    if (key === 'updated_at') {
      return moment(data).format()
    }
    if (key === 'avatar') {
      return null
    }
    if (key === 'description') {
      return _.truncate(data, 100)
    }
    return data
  }
  renderAccountPage = ({ data: accounts, individualLoadingStatus, pagination, fetch }) => {
    return (
      <AccountPageContainer>
        <TopNavigation divider={this.props.divider} title={'Accounts'} buttons={[this.renderCreateAccountButton()]} />
        <SortableTableContainer
          ref={table => (this.table = table)}
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
          perPage: 12,
          search: queryString.parse(this.props.location.search).search
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(AccountPage)
