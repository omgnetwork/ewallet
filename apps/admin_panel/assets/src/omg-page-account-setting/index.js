import React, { Component } from 'react'
import styled from 'styled-components'
import { Input, Button, Icon } from '../omg-uikit'
import ImageUploaderAvatar from '../omg-uploader/ImageUploaderAvatar'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { currentAccountProviderHoc } from '../omg-account-current/currentAccountProvider'
import SortableTable from '../omg-table'
import { withRouter } from 'react-router-dom'
import InviteModal from '../omg-invite-modal'
import InviteListProvider from '../omg-invite/inviteListProvider'
import { updateCurrentAccount } from '../omg-account-current/action'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import moment from 'moment'
import Link from '../omg-links'

import TabsManager from '../omg-tabs'

const columns = [
  { key: 'account_role', title: 'ROLE', sort: true },
  { key: 'username', title: 'MEMBER NAME', sort: true },
  { key: 'email', title: 'EMAIL', sort: true },
  { key: 'since', title: 'LAST UPDATED', sort: true },
  { key: 'status', title: 'STATUS', sort: true }
]
const AccountSettingContainer = styled.div`
  td:first-child {
    width: 10%;
  }
  td:nth-child(3) {
    width: 40%;
  }
  a {
    color: inherit;
    padding-bottom: 5px;
    display: block;
  }
`
const ProfileSection = styled.div`
  min-width: 250px;
  max-width: 30%;
  flex: 1 1 auto;
  padding-right: 100px;
  input {
    margin-top: 40px;
  }
  button {
    margin-top: 40px;
  }
`
const ContentContainer = styled.div`
  display: flex;
`
const TableSection = styled.div`
  flex: 1 1 auto;
`
const Avatar = styled(ImageUploaderAvatar)`
  margin: 0;
`
const InviteButton = styled(Button)`
  padding-left: 30px;
  padding-right: 30px;
`

const enhance = compose(
  withRouter,
  currentAccountProviderHoc,
  connect(
    null,
    { updateCurrentAccount }
  )
)
class AccountSettingPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    updateCurrentAccount: PropTypes.func.isRequired,
    loadingStatus: PropTypes.string,
    currentAccount: PropTypes.object,
    location: PropTypes.object
  }

  constructor (props) {
    super(props)
    this.state = {
      inviteModalOpen: queryString.parse(props.location.search).invite || false,
      name: '',
      description: '',
      avatar: '',
      submitStatus: 'DEFAULT'
    }
  }
  componentWillMount = () => {
    this.setInitialAccountState()
  }
  componentWillReceiveProps = props => {
    this.setInitialAccountState()
  }
  setInitialAccountState = () => {
    if (this.props.loadingStatus === 'SUCCESS' && !this.state.accountLoaded) {
      this.setState({
        name: this.props.currentAccount.name,
        description: this.props.currentAccount.description,
        avatar: this.props.currentAccount.avatar.original,
        accountLoaded: true
      })
    }
  }
  onChangeImage = ({ file }) => {
    this.setState({ image: file })
  }
  onRequestClose = () => {
    this.setState({ inviteModalOpen: false })
  }
  onClickInviteButton = () => {
    this.setState({ inviteModalOpen: true })
  }
  onChangeName = e => {
    this.setState({ name: e.target.value })
  }
  onChangeDescription = e => {
    this.setState({ description: e.target.value })
  }
  onClickUpdateAccount = async e => {
    e.preventDefault()
    this.setState({ submitStatus: 'SUBMITTING' })
    try {
      const result = await this.props.updateCurrentAccount({
        accountId: this.props.match.params.accountId,
        name: this.state.name,
        description: this.state.description,
        avatar: this.state.image
      })

      if (result.data) {
        this.setState({ submitStatus: 'SUBMITTED' })
      } else {
        this.setState({ submitStatus: 'FAILED' })
      }
    } catch (error) {
      this.setState({ submitStatus: 'FAILED' })
    }
  }

  renderExportButton = () => {
    return (
      <Button size='small' styleType='ghost' onClick={this.onClickExport} key={'export'}>
        <Icon name='Export' />
        <span>Export</span>
      </Button>
    )
  }
  renderInviteButton = () => {
    return (
      <InviteButton size='small' onClick={this.onClickInviteButton} key={'create'}>
        <Icon name='Plus' /> <span>Invite</span>
      </InviteButton>
    )
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'since') {
      return moment(data).format('DD/MM/YYYY hh:mm:ss')
    }
    if (key === 'username') {
      return data || '-'
    }
    if (key === 'status') {
      return data === 'active' ? 'Active' : 'Pending'
    }
    return data
  }
  renderAccountSettingTab () {
    return (
      <ProfileSection>
        {this.props.loadingStatus === 'SUCCESS' && (
          <form onSubmit={this.onClickUpdateAccount} noValidate>
            <Avatar
              onChangeImage={this.onChangeImage}
              size='180px'
              placeholder={this.state.avatar}
            />
            <Input
              prefill
              placeholder={'Name'}
              value={this.state.name}
              onChange={this.onChangeName}
            />
            <Input
              placeholder={'Description'}
              value={this.state.description}
              onChange={this.onChangeDescription}
              prefill
            />
            {/* <Input prefill placeholder={'Group'} value={this.state.group} /> */}
            <Button
              size='small'
              type='submit'
              key={'save'}
              disabled={
                this.props.currentAccount.name === this.state.name &&
                this.props.currentAccount.description === this.state.description &&
                !this.state.image
              }
              loading={this.state.submitStatus === 'SUBMITTING'}
            >
              <span>Save Change</span>
            </Button>
          </form>
        )}
      </ProfileSection>
    )
  }
  renderMemberTab () {
    return (
      <TableSection>
        <InviteListProvider
          render={({ inviteList, loadingStatus }) => {
            return (
              <SortableTable
                rows={inviteList}
                columns={columns}
                perPage={99999}
                loadingStatus={loadingStatus}
                loadingRowNumber={7}
                rowRenderer={this.rowRenderer}
                navigation={false}
              />
            )
          }}
        />
      </TableSection>
    )
  }
  render () {
    const tabIndex = {
      account: 0,
      members: 1
    }
    return (
      <AccountSettingContainer>
        <TopNavigation
          title='Account Setting'
          buttons={[this.renderInviteButton()]}
          secondaryAction={false}
          types={false}
        />
        <TabsManager
          onClickTab={this.onClickTab}
          activeIndex={tabIndex[this.props.match.params.state]}
          tabs={[
            {
              title: <Link to={'/setting/account'}>ACCOUNT</Link>,
              content: this.renderAccountSettingTab()
            },
            {
              title: <Link to={'/setting/members'}>MEMBERS</Link>,
              content: this.renderMemberTab()
            }
          ]}
        />
        <InviteModal open={this.state.inviteModalOpen} onRequestClose={this.onRequestClose} />
      </AccountSettingContainer>
    )
  }
}
export default enhance(AccountSettingPage)
