import React, { Component } from 'react'
import TopNavigation from '../omg-page-layout/TopNavigation'
import styled from 'styled-components'
import SortableTable from '../omg-table'
import { Button, Icon, Avatar } from '../omg-uikit'
import CreateAccountModal from '../omg-create-account-modal'
import ExportModal from '../omg-export-modal'
import AccountProvider from '../omg-account/accountsProvider'
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
  th:first-child {
    width: 50%;
  }
`
const SortableTableContainer = styled.div`
  position: relative;
`
const NameColumn = styled.div`
  > span {
    margin-left: 10px;
  }
`
class AccountPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    history: PropTypes.object,
    location: PropTypes.object
  }
  constructor (props) {
    super(props)
    this.state = {
      createAccountModalOpen: false,
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
      { key: 'description', title: 'DESCRIPTION', sort: true },
      { key: 'created_at', title: 'CREATED DATE', sort: true },
      { key: 'avatar', title: 'AVATAR', hide: true }
    ]
  }
  getRow = accounts => {
    return accounts.map(d => {
      return {
        ...d,
        avatar: d.avatar.thumb
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
  renderAccountPage = ({ accounts, loadingStatus }) => {
    return (
      <AccountPageContainer>
        <TopNavigation
          title={'Account'}
          buttons={[this.renderCreateAccountButton()]}
        />
        <SortableTableContainer innerRef={table => (this.table = table)}>
          <SortableTable
            dataSource={this.getRow(accounts)}
            columns={this.getColumns(accounts)}
            loading={loadingStatus === 'DEFAULT' || loadingStatus === 'INITIATED'}
            perPage={20}
            rowRenderer={this.rowRenderer}
            onClickRow={this.onClickRow}
          />
        </SortableTableContainer>
        <CreateAccountModal
          open={this.state.createAccountModalOpen}
          onRequestClose={this.onRequestCloseCreateAccount}
        />
        <ExportModal open={this.state.exportModalOpen} onRequestClose={this.onRequestCloseExport} />
      </AccountPageContainer>
    )
  }

  render () {
    return (
      <AccountProvider
        render={this.renderAccountPage}
        {...this.state}
        {...this.props}
        search={queryString.parse(this.props.location.search).search}
      />
    )
  }
}

export default withRouter(AccountPage)
