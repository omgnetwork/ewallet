import React, { Component } from 'react'
import styled from 'styled-components'
import { Input, Button } from '../omg-uikit'
import ImageUploaderAvatar from '../omg-uploader/ImageUploaderAvatar'
import { currentUserProviderHoc } from '../omg-user-current/currentUserProvider'
import { withRouter } from 'react-router-dom'
import { updateCurrentAccount } from '../omg-account-current/action'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import PropTypes from 'prop-types'
const UserSettingContainer = styled.div`
  padding-top: 20px;
  button {
    margin-top: 40px;
  }
  h2 {
    margin-bottom: 30px;
  }
`
const StyledInput = styled(Input)`
  margin-bottom: 40px;
`
const Avatar = styled(ImageUploaderAvatar)`
  margin: 0;
  display: inline-block;
`
const InputsContainer = styled.div`
  display: inline-block;
  max-width: 350px;
  width: 100%;
  vertical-align: top;
`
const AvatarContainer = styled.div`
  display: inline-block;
  vertical-align: top;
  margin-right: 50px;
`
const ChangePasswordContainer = styled.div`
  > div {
    color: ${props => props.theme.colors.B100};
  }
  a {
    color: ${props => props.theme.colors.BL400};
  }
`
const enhance = compose(
  currentUserProviderHoc,
  connect(
    null,
    { updateCurrentAccount }
  ),
  withRouter
)

class UserSettingPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    updateCurrentAccount: PropTypes.func.isRequired,
    loadingStatus: PropTypes.string,
    currentUser: PropTypes.object
  }
  state = {
    email: ''
  }
  componentWillReceiveProps = props => {
    this.setInitialCurrentUserState()
  }
  componentDidMount = () => {
    this.setInitialCurrentUserState()
  }
  setInitialCurrentUserState = () => {
    if (this.props.loadingStatus === 'SUCCESS' && !this.state.accountLoaded) {
      this.setState({
        email: this.props.currentUser.email,
        accountLoaded: true
      })
    }
  }
  onChangeImage = ({ file }) => {
    this.setState({ image: file })
  }
  onChangeEmail = e => {
    this.setState({ email: e.target.value })
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
  render () {
    return (
      <UserSettingContainer>
        <h2>User Setting</h2>
        {this.props.loadingStatus === 'SUCCESS' && (
          <form onSubmit={this.onClickUpdateAccount} noValidate>
            <AvatarContainer>
              <Avatar
                onChangeImage={this.onChangeImage}
                size='180px'
                placeholder={this.state.avatar}
              />
            </AvatarContainer>
            <InputsContainer>
              <StyledInput
                placeholder={'Email'}
                value={this.state.email}
                prefill
                onChange={this.onChangeEmail}
              />
              <ChangePasswordContainer>
                <div>Password</div>
                <a>Change password</a>
              </ChangePasswordContainer>
              <Button size='small' type='submit' key={'save'}>
                Save Change
              </Button>
            </InputsContainer>
          </form>
        )}
      </UserSettingContainer>
    )
  }
}
export default enhance(UserSettingPage)
