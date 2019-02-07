import React, { Component } from 'react'
import { Input, Button } from '../omg-uikit'
import styled from 'styled-components'
import { Link, withRouter } from 'react-router-dom'
import queryString from 'query-string'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { createUser } from '../omg-member/action'
import { compose } from 'recompose'
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

const enhance = compose(
  withRouter,
  connect(
    null,
    { createUser }
  )
)
class ForgetPasswordForm extends Component {
  static propTypes = {
    location: PropTypes.object.isRequired,
    createUser: PropTypes.func.isRequired
  }
  state = {
    newPassword: '',
    newPasswordError: false,
    reEnteredNewPassword: '',
    reEnteredNewPasswordError: false,
    submitStatus: null
  }

  validatePassword = password => {
    return password.length >= 8
  }
  validateReEnteredNewPassword = (newPassword, reEnteredNewPassword) => {
    return newPassword === reEnteredNewPassword && newPassword !== '' && reEnteredNewPassword !== ''
  }
  onSubmit = async e => {
    e.preventDefault()
    try {
      const { email, token } = queryString.parse(this.props.location.search)
      const newPasswordError = !this.validatePassword(this.state.newPassword)
      const reEnteredNewPasswordError = !this.validateReEnteredNewPassword(
        this.state.newPassword,
        this.state.reEnteredNewPassword
      )
      this.setState({
        newPasswordError,
        reEnteredNewPasswordError,
        submitStatus: !newPasswordError && !reEnteredNewPasswordError ? 'SUBMITTED' : null
      })
      if (!newPasswordError && !reEnteredNewPasswordError) {
        const result = await this.props.createUser({
          email,
          resetToken: token,
          password: this.state.newPassword,
          passwordConfirmation: this.state.reEnteredNewPassword
        })
        if (result.data) {
          this.setState({ submitStatus: 'SUCCESS' })
        } else {
          this.setState({
            submitStatus: 'FAILED',
            submitErrorText:
              _.get(result, 'error.code') || _.get(result, 'error.message') || 'Invite Failed.'
          })
        }
      }
    } catch (error) {
      this.setState({
        submitStatus: 'FAILED',
        submitErrorText: _.get(error, 'message', 'Something went wrong.')
      })
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
  render () {
    const { email } = queryString.parse(this.props.location.search)
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        {this.state.submitStatus !== 'SUCCESS' ? (
          <div>
            <h4>Create Password ({email})</h4>
            <p>Create new password with at least 8 characters</p>
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
            <Button
              size='large'
              type='submit'
              fluid
              loading={this.state.submitStatus === 'SUBMITTED'}
            >
              Create Account
            </Button>
          </div>
        ) : (
          <UpdateSuccessfulContainer>
            <h4>Account created successfully</h4>
          </UpdateSuccessfulContainer>
        )}

        <Link to='/login/' className='back-link'>
          Go back to Login
        </Link>
        <Error error={this.state.submitStatus === 'FAILED'}>{this.state.submitErrorText}</Error>
      </Form>
    )
  }
}

export default enhance(ForgetPasswordForm)
