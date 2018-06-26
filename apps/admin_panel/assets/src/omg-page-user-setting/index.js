import React, { Component } from 'react'
import styled from 'styled-components'
import { Input, Button } from '../omg-uikit'
import ImageUploaderAvatar from '../omg-uploader/ImageUploaderAvatar'
import { currentUserProviderHoc } from '../omg-user-current/currentUserProvider'
import { withRouter } from 'react-router-dom'
import { updateCurrentUser } from '../omg-user-current/action'
import { connect } from 'react-redux'
import { compose } from 'recompose'
import PropTypes from 'prop-types'
const UserSettingContainer = styled.div`
  padding-top: 20px;
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
    { updateCurrentUser }
  ),
  withRouter
)

class UserSettingPage extends Component {
  static propTypes = {
    match: PropTypes.object,
    updateCurrentUser: PropTypes.func.isRequired,
    loadingStatus: PropTypes.string,
    currentUser: PropTypes.object
  }
  state = {
    email: '',
    submitStatus: 'DEFAULT'
  }
  componentWillReceiveProps = props => {
    this.setInitialCurrentUserState()
  }
  componentDidMount = () => {
    this.setInitialCurrentUserState()
  }
  setInitialCurrentUserState = () => {
    if (this.props.loadingStatus === 'SUCCESS' && !this.state.currentUserLoaded) {
      this.setState({
        email: this.props.currentUser.email,
        avatarPlaceholder: this.props.currentUser.avatar.original,
        currentUserLoaded: true
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
    try {
      this.setState({submitStatus: 'SUBMITTING'})
      const result = await this.props.updateCurrentUser({
        email: this.state.email,
        avatar: this.state.image
      })
      if (result.success) {
        this.setState({submitStatus: 'SUBMITTED'})
      } else {
        this.setState({submitStatus: 'FAILED'})
      }
    } catch (error) {
      this.setState({submitStatus: 'FAILED'})
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
                placeholder={this.state.avatarPlaceholder}
              />
            </AvatarContainer>
            <InputsContainer>
              <StyledInput
                placeholder={'Email'}
                value={this.state.email}
                prefill
                onChange={this.onChangeEmail}
              />
              {/* <ChangePasswordContainer>
                <div>Password</div>
                <a>Change password</a>
              </ChangePasswordContainer> */}
              <Button size='small' type='submit' key={'save'} loading={this.state.submitStatus === 'SUBMITTING'}>
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
