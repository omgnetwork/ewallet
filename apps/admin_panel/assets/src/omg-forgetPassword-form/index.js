import React, { Component } from 'react'
import { Input, Button } from '../omg-uikit'
import styled from 'styled-components'
import { Link } from 'react-router-dom'
import { resetPassword } from '../omg-session/action'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'
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
const enhance = compose(connect(null, { resetPassword }))
class ForgetPasswordForm extends Component {
  static propTypes = {
    resetPassword: PropTypes.func
  }
  state = {
    email: '',
    emailError: false,
    submitStatus: null
  }

  validateEmail = email => {
    return !/@/.test(email) || email.length === 0
  }
  validatePassword = password => {
    return password.length === 0
  }
  onSubmit = async e => {
    e.preventDefault()
    const emailError = this.validateEmail(this.state.email)
    this.setState({
      emailError,
      submitStatus: emailError ? 'ERROR' : 'SUBMITTED'
    })
    if (!emailError) {
      const result = await this.props.resetPassword({
        email: this.state.email,
        redirectUrl: window.location.href
      })
      this.setState({ submitStatus: result.data.success ? 'SUCCESS' : 'FAILED' })
    }
  }
  onEmailInputChange = e => {
    const value = e.target.value
    this.setState({
      email: value,
      emailError: this.state.submitStatus === 'ERROR' && this.validateEmail(value)
    })
  }
  render () {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <h4>Reset Password</h4>
        <p>Please enter your recovery email to reset password.</p>
        <Input
          placeholder='email@domain.com'
          error={this.state.emailError}
          errorText='Invalid email'
          success={this.state.submitStatus === 'SUCCESS'}
          successText={'Email has been sent, please check your email.'}
          onChange={this.onEmailInputChange}
          value={this.state.email}
          disabled={this.state.submitted}
        />
        <Button size='large' type='submit' fluid loading={this.state.submitStatus === 'SUBMITTED'}>
          Send Request Email
        </Button>
        <Link to='/login/' className='back-link'>
          Go back to Login
        </Link>
      </Form>
    )
  }
}

export default enhance(ForgetPasswordForm)
