import React, { Component } from 'react'
import styled from 'styled-components'
import { Input, Button, Icon } from '../omg-uikit'
import ImageUploaderAvatar from '../omg-uploader/ImageUploaderAvatar'
import TopNavigation from '../omg-page-layout/TopNavigation'
import { getAccountById, updateAccount } from '../omg-account/action'
import { selectGetAccountById } from '../omg-account/selector'
import { withRouter } from 'react-router-dom'
import InviteModal from '../omg-invite-modal'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import moment from 'moment'
import Copy from '../omg-copy'

const AccountSettingContainer = styled.div`
  a {
    color: inherit;
    padding-bottom: 5px;
    display: block;
  }
  padding-bottom: 50px;
`
const ProfileSection = styled.div`
  padding-top: 40px;
  input {
    margin-top: 40px;
  }
  button {
    margin-top: 40px;
  }
  form {
    display: flex;
    > div {
      display: inline-block;
    }
    > div:first-child {
      margin-right: 40px;
    }
    > div:nth-child(2) {
      max-width: 300px;
      width: 100%;
    }
  }
`
const Avatar = styled(ImageUploaderAvatar)`
  margin: 0;
`
const InviteButton = styled(Button)`
  padding-left: 30px;
  padding-right: 30px;
`
export const NameColumn = styled.div`
  i[name='Copy'] {
    margin-left: 5px;
    cursor: pointer;
    visibility: hidden;
    color: ${props => props.theme.colors.S500};
    :hover {
      color: ${props => props.theme.colors.B100};
    }
  }
`

const enhance = compose(
  withRouter,
  connect(
    (state, props) => ({
      currentAccount: selectGetAccountById(state)(props.match.params.accountId)
    }),
    { getAccountById, updateAccount }
  )
)

class AccountSettingPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    getAccountById: PropTypes.func.isRequired,
    updateAccount: PropTypes.func,
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
  componentDidMount () {
    this.setInitialAccountState()
  }
  async setInitialAccountState () {
    if (this.props.currentAccount) {
      this.setState({
        name: this.props.currentAccount.name,
        description: this.props.currentAccount.description,
        avatar: this.props.currentAccount.avatar.original
      })
    } else {
      const result = await this.props.getAccountById(this.props.match.params.accountId)
      if (result.data) {
        this.setState({
          name: result.data.name,
          description: result.data.description,
          avatar: result.data.avatar.original
        })
      }
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
      const result = await this.props.updateAccount({
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
        <Icon name='Plus' /> <span>Invite Member</span>
      </InviteButton>
    )
  }
  rowRenderer = (key, data, rows) => {
    if (key === 'updated_at') {
      return moment(data).format()
    }
    if (key === 'username') {
      return data || '-'
    }
    if (key === 'status') {
      return data === 'active' ? 'Active' : 'Pending'
    }
    if (key === 'id') {
      return (
        <NameColumn>
          <span>{data}</span> <Copy data={data} />
        </NameColumn>
      )
    }
    return data
  }
  renderAccountSettingTab () {
    return (
      <ProfileSection>
        {this.props.currentAccount && (
          <form onSubmit={this.onClickUpdateAccount} noValidate>
            <Avatar
              onChangeImage={this.onChangeImage}
              size='180px'
              placeholder={this.state.avatar}
            />
            <div>
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
            </div>
          </form>
        )}
      </ProfileSection>
    )
  }
  render () {
    return (
      <AccountSettingContainer>
        <TopNavigation
          title='Account Settings'
          buttons={[this.renderInviteButton()]}
          secondaryAction={false}
          types={false}
        />
        {this.renderAccountSettingTab()}
        <InviteModal open={this.state.inviteModalOpen} onRequestClose={this.onRequestClose} />
      </AccountSettingContainer>
    )
  }
}
export default enhance(AccountSettingPage)
