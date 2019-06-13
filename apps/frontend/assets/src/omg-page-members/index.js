import React, { Component } from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import moment from 'moment'
import queryString from 'query-string'
import styled from 'styled-components'

import TopNavigation from '../omg-page-layout/TopNavigation'
import SortableTable from '../omg-table'
import { Button, Icon, Id } from '../omg-uikit'
import MembersFetcher from '../omg-member/MembersFetcher'
import { createMemberSearchQuery } from '../omg-member/searchField'
import InviteModal from '../omg-invite-modal'

const MemberPageContainer = styled.div`
  position: relative;
  padding-bottom: 100px;
  td:first-child {
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
    cursor: pointer;
    visibility: hidden;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B300};
    }
  }
  i[name='Profile'] {
    margin-right: 15px;
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
  display: flex;
  flex-direction: row;
`

class MembersPage extends Component {
  static propTypes = {
    location: PropTypes.object,
    history: PropTypes.object,
    scrollTopContentContainer: PropTypes.func,
    query: PropTypes.object,
    fetcher: PropTypes.func,
    navigation: PropTypes.bool,
    onClickRow: PropTypes.func,
    columns: PropTypes.array,
    divider: PropTypes.bool,
    showInviteButton: PropTypes.bool
  }
  static defaultProps = {
    query: {},
    fetcher: MembersFetcher,
    showInviteButton: false,
    columns: [
      { key: 'id', title: 'ADMIN ID', sort: true },
      { key: 'email', title: 'EMAIL', sort: true },
      { key: 'global_role', title: 'GLOBAL ROLE', sort: true },
      { key: 'role', title: 'ACCOUNT ROLE', sort: true },
      { key: 'status', title: 'STATUS', sort: true },
      { key: 'created_at', title: 'ADDED AT', sort: true }
    ]
  }
  constructor (props) {
    super(props)
    this.state = {
      createAccountModalOpen: false,
      inviteModalOpen: false
    }
  }
  onRequestClose = () => {
    this.setState({ inviteModalOpen: false })
  }
  onClickRow = (data, index) => e => {
    this.props.history.push(`/admins/${data.id}`)
  }
  onClickInviteButton = () => {
    this.setState({ inviteModalOpen: true })
  }
  renderCreateAccountButton = () => {
    return (
      <Button size='small' onClick={this.onClickCreateAccount} key={'create'}>
        <Icon name='Plus' /><span>Create Account</span>
      </Button>
    )
  }
  getRow = admins => {
    return admins.map(admin => ({
      ...admin.user,
      global_role: admin.user.global_role,
      role: admin.role,
      avatar: _.get(admin, 'user.avatar.thumb')
    }))
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
            <Icon name='Profile' /><Id>{data}</Id>
          </UserIdContainer>
        )
      case 'email':
        return data || '-'
      case 'global_role':
        return _.startCase(data) || '-'
      case 'role':
        return _.startCase(data)
      case 'status':
        return _.startCase(data)
      default:
        return data
    }
  }
  renderInviteButton = () => {
    return (
      <Button size='small' onClick={this.onClickInviteButton} key={'create'}>
        <Icon name='Plus' /><span>Invite Member</span>
      </Button>
    )
  }

  renderAdminPage = ({ data: admins, individualLoadingStatus, pagination, fetch }) => {
    return (
      <MemberPageContainer>
        <TopNavigation
          divider={this.props.divider}
          title={'Admins'}
          buttons={[this.props.showInviteButton ? this.renderInviteButton() : null]}
        />
        <SortableTableContainer ref={table => (this.table = table)}>
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
        <InviteModal open={this.state.inviteModalOpen} onRequestClose={this.onRequestClose} onInviteSuccess={fetch} />
      </MemberPageContainer>
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
          ...createMemberSearchQuery(queryString.parse(this.props.location.search).search),
          ...this.props.query
        }}
        onFetchComplete={this.props.scrollTopContentContainer}
      />
    )
  }
}

export default withRouter(MembersPage)
