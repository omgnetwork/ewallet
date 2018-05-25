import React, { Component } from 'react'
import { Input, Button } from '../omg-uikit'
import styled from 'styled-components'
import { Link } from 'react-router-dom'
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
class ForgetPasswordForm extends Component {
  state = {
    newPassword: '',
    newPasswordError: false,
    reEnteredNewPassword: '',
    reEnteredNewPasswordError: false
  }

  validatePassword = password => {
    return password.length === 0
  }
  validateReEnteredNewPassword = (newPassword, reEnteredNewPassword) => {
    return newPassword !== reEnteredNewPassword || newPassword === '' || reEnteredNewPassword === ''
  }
  onSubmit = e => {
    e.preventDefault()
    const newPasswordError = this.validatePassword(this.state.newPassword)
    const reEnteredNewPasswordError = this.validateReEnteredNewPassword(this.state.newPassword, this.state.reEnteredNewPassword)
    this.setState({
      newPasswordError,
      reEnteredNewPasswordError,
      submitted: !newPasswordError && !reEnteredNewPasswordError
    })
  }
  onNewPasswordInputChange = e => {
    const value = e.target.value
    this.setState({ newPassword: value, newPasswordError: this.state.submitted && this.validatePassword(value) })
  }
  onReEnteredNewPasswordInputChange = e => {
    const value = e.target.value
    this.setState({
      reEnteredNewPassword: value,
      reEnteredNewPasswordError: this.validateReEnteredNewPassword(this.state.newPassword, value)
    })
  }
  render () {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <h4>Reset Password</h4>
        <p>Create new password with 8 - 16 characters</p>
        <Input
          placeholder='New password'
          error={this.state.newPasswordError}
          errorText='Field cannot be empty'
          onChange={this.onNewPasswordInputChange}
          value={this.state.newPassword}
          disabled={this.state.submitted}
          type='password'
        />
        <Input
          placeholder='Re-enter new password'
          type='password'
          error={this.state.reEnteredNewPasswordError}
          errorText='Password does not match'
          onChange={this.onReEnteredNewPasswordInputChange}
          value={this.state.reEnteredNewPassword}
          disabled={this.state.submitted}
        />
        <Button size='large' type='submit' fluid loading={this.state.submitted}>
          Reset Password
        </Button>
        <Link to='/login/' className='back-link'>
          Go back to Login
        </Link>
      </Form>
    )
  }
}

export default ForgetPasswordForm
