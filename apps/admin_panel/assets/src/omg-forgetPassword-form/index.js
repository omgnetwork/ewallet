import React, { Component } from 'react'
import { Input, Button } from '../omg-uikit'
import styled from 'styled-components'
import { Link, withRouter } from 'react-router-dom'
import { sendResetPasswordEmail } from '../omg-session/action'
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
const SendEmailSuccessfulContainer = styled.div`
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
const enhance = compose(withRouter, connect(null, { sendResetPasswordEmail }))
class ForgetPasswordForm extends Component {
  static propTypes = {
    sendResetPasswordEmail: PropTypes.func,
    location: PropTypes.func
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
      const result = await this.props.sendResetPasswordEmail({
        email: this.state.email,
        redirectUrl: window.location.href.replace(
          this.props.location.pathname,
          '/create-new-password/'
        )
      })
      if (result.data) {
        this.setState({ submitStatus: 'SUCCESS' })
      } else {
        this.setState({ submitStatus: 'FAILED', submitErrorText: result.error.description })
      }
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
        {this.state.submitStatus === 'SUCCESS' ? (
          <SendEmailSuccessfulContainer>
            <h4>Email has been sent, please check your email</h4>
          </SendEmailSuccessfulContainer>
        ) : (
          <div>
            <h4>Reset Password</h4>
            <p>Please enter your recovery email to reset password.</p>
            <Input
              placeholder='email@domain.com'
              error={this.state.emailError}
              errorText='Invalid email'
              onChange={this.onEmailInputChange}
              value={this.state.email}
              disabled={this.state.submitted}
            />
            <Button
              size='large'
              type='submit'
              fluid
              loading={this.state.submitStatus === 'SUBMITTED'}
            >
              Send Request Email
            </Button>
          </div>
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
