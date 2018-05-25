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
import PropTypes from 'prop-types'
const columns = [
  { key: 'role', title: 'ROLE', sort: true },
  { key: 'member', title: 'MEMBER NAME', sort: true },
  { key: 'email', title: 'EMAIL', sort: true },
  { key: 'since', title: 'MEMBER SINCE', sort: true }
]
const AccountSettingContainer = styled.div``
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
  connect(null, { updateCurrentAccount }),
)
class AccountSettingPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    updateCurrentAccount: PropTypes.func.isRequired,
    loadingStatus: PropTypes.string,
    currentAccount: PropTypes.object
  }

  constructor (props) {
    super(props)
    this.state = {
      inviteModalOpen: false
    }
  }
  componentWillReceiveProps = props => {
    this.setInitialAccountState()
  }
  componentWillMount = () => {
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
    const result = await this.props.updateCurrentAccount({
      accountId: this.props.match.params.accountId,
      name: this.state.name,
      description: this.state.description,
      avatar: this.state.image
    })
    if (result.data.success) {
      this.setState({ image: null })
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
  render () {
    return (
      <AccountSettingContainer>
        <TopNavigation
          title='Account Setting'
          buttons={[]}
          secondaryAction={false}
          types={false}
        />
        <ContentContainer>
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
                  defaultValue={this.props.currentAccount.name}
                  onChange={this.onChangeName}
                />
                <Input
                  placeholder={'Description'}
                  value={this.state.description}
                  onChange={this.onChangeDescription}
                  defaultValue={this.props.currentAccount.description}
                  prefill
                />
                {/* <Input prefill placeholder={'Group'} value={this.state.group} /> */}
                <Button size='small' type='submit' key={'save'}>
                  <span>Save Change</span>
                </Button>
              </form>
            )}
          </ProfileSection>
          <TableSection>
            <InviteListProvider
              render={({ inviteList, loadingStatus }) => {
                const rows = inviteList.map(invite => {
                  return {
                    key: invite.id,
                    role: invite.account_role,
                    email: invite.email,
                    member: invite.username || '-',
                    since: invite.created_at
                  }
                })
                return <SortableTable dataSource={rows} columns={columns} perPage={99999} loading={loadingStatus === 'DEFAULT'} loadingRowNumber={7} />
              }}
            />
          </TableSection>
        </ContentContainer>
        <InviteModal open={this.state.inviteModalOpen} onRequestClose={this.onRequestClose} />
      </AccountSettingContainer>
    )
  }
}
export default enhance(AccountSettingPage)
