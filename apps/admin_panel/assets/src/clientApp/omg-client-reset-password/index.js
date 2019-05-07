import React, { Component } from 'react'
import styled from 'styled-components'
import { withRouter } from 'react-router-dom'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import { compose } from 'recompose'
import PasswordValidator from 'password-validator'

import { Input, Button } from '../../omg-uikit'
import AuthFormLayout from '../../omg-layout/authFormLayout'
import { updateUserPassword } from '../../services/clientService'
import { isMobile } from '../../utils/device'

const schema = new PasswordValidator()
schema.is().min(8).has().uppercase().has().lowercase().has().digits().has().symbols()

const Form = styled.form`
  text-align: left;
  input {
    margin-top: 35px;
  }
  h4 {
    margin-top: 30px;
  }
  p {
    margin-top: 10px;
  }
  .back-link {
    margin-top: 20px;
    display: block;
    text-align: center;
  }
`
const UpdateSuccessfulContainer = styled.div`
  text-align: center;
`
const Error = styled.div`
  color: ${props => props.theme.colors.R400};
  text-align: center;
  padding: 10px 0;
  overflow: hidden;
  max-height: ${props => (props.error ? '100px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
`
const MobileRedirect = styled.div`
  text-align: center;
  padding: 20px;
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  font-size: 18px;
  a {
    cursor: pointer;
  }
`
const enhance = compose(withRouter)
class ForgetPasswordForm extends Component {
  static propTypes = {
    location: PropTypes.object.isRequired
  }

  constructor (props) {
    super(props)
    const { forward_url: forwardUrl } = queryString.parse(this.props.location.search)
    const [protocol] = forwardUrl ? String(forwardUrl).split('://') : []
    const isforwardUrlWebProtocol = ['http', 'https'].includes(protocol)
    this.isforwardUrlWebProtocol = isforwardUrlWebProtocol
    this.state = {
      newPassword: '',
      newPasswordError: false,
      reEnteredNewPassword: '',
      reEnteredNewPasswordError: false,
      submitStatus: null,
      maybeAppExist: isforwardUrlWebProtocol ? false : isMobile() ? !!forwardUrl : false
    }
    if (forwardUrl) {
      window.location = forwardUrl
    }
  }

  validatePassword = password => {
    return schema.validate(password)
  }
  validateReEnteredNewPassword = (newPassword, reEnteredNewPassword) => {
    return newPassword === reEnteredNewPassword && newPassword !== '' && reEnteredNewPassword !== ''
  }
  onSubmit = async e => {
    e.preventDefault()
    const { email, token } = queryString.parse(this.props.location.search)
    const newPasswordError = !this.validatePassword(this.state.newPassword)
    const reEnteredNewPasswordError = !this.validateReEnteredNewPassword(this.state.newPassword, this.state.reEnteredNewPassword)
    this.setState({
      newPasswordError,
      reEnteredNewPasswordError,
      submitStatus: !newPasswordError && !reEnteredNewPasswordError ? 'SUBMITTED' : null
    })
    if (!newPasswordError && !reEnteredNewPasswordError) {
      const result = await updateUserPassword({
        email,
        token,
        password: this.state.newPassword,
        passwordConfirmation: this.state.reEnteredNewPassword
      })
      if (result.data.success) {
        this.setState({ submitStatus: 'SUCCESS' })
      } else {
        this.setState({ submitStatus: 'FAILED', submitErrorText: result.data.data.description })
      }
    }
  }
  onNewPasswordInputChange = e => {
    const value = e.target.value
    this.setState({
      newPassword: value,
      newPasswordError: this.state.submitStatus && !this.validatePassword(value)
    })
  }
  onReEnteredNewPasswordInputChange = e => {
    const value = e.target.value
    this.setState({
      reEnteredNewPassword: value,
      reEnteredNewPasswordError: !this.validateReEnteredNewPassword(this.state.newPassword, value)
    })
  }
  onClickShowForm = e => {
    e.preventDefault()
    this.setState({ maybeAppExist: false })
  }
  render () {
    const { email } = queryString.parse(this.props.location.search)
    return this.state.maybeAppExist || this.isforwardUrlWebProtocol ? (
      <MobileRedirect>
        We are trying to open an app for forward url for you, if this does not work <a onClick={this.onClickShowForm}>Click here</a> to reset password
      </MobileRedirect>
    ) : (
      <AuthFormLayout>
        <Form onSubmit={this.onSubmit} noValidate>
          {this.state.submitStatus !== 'SUCCESS' ? (
            <div>
              <h4>Create Password ({email})</h4>
              <p>Create new password with at least 8 characters, symbol, number, uppercase and lowercase</p>
              <Input
                placeholder='New password'
                error={this.state.newPasswordError}
                errorText='Invalid password'
                onChange={this.onNewPasswordInputChange}
                value={this.state.newPassword}
                disabled={this.state.submitStatus === 'SUBMITTED'}
                type='password'
              />
              <Input
                placeholder='Re-enter new password'
                type='password'
                error={this.state.reEnteredNewPasswordError}
                errorText='Password does not match'
                onChange={this.onReEnteredNewPasswordInputChange}
                value={this.state.reEnteredNewPassword}
                disabled={this.state.submitStatus === 'SUBMITTED'}
              />
              <Button size='large' type='submit' fluid loading={this.state.submitStatus === 'SUBMITTED'}>
                <span>Reset Password</span>
              </Button>
            </div>
          ) : (
            <UpdateSuccessfulContainer>
              <h4>Password reset successful</h4>
            </UpdateSuccessfulContainer>
          )}
          <Error error={this.state.submitStatus === 'FAILED'}>{this.state.submitErrorText}</Error>
        </Form>
      </AuthFormLayout>
    )
  }
}

export default enhance(ForgetPasswordForm)
