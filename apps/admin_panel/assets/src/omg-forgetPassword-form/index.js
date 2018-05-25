import React, { Component } from 'react'
import { Input, Button } from '../omg-uikit'
import styled from 'styled-components'
import {Link} from 'react-router-dom'
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
    email: '',
    emailError: false
  }

  validateEmail = email => {
    return !/@/.test(email) || email.length === 0
  }
  validatePassword = password => {
    return password.length === 0
  }
  onSubmit = e => {
    e.preventDefault()
    const emailError = this.validateEmail(this.state.email)
    this.setState({
      emailError,
      submitted: !emailError
    })
  }
  onEmailInputChange = e => {
    const value = e.target.value
    this.setState({ email: value, emailError: this.state.submitted && this.validateEmail(value) })
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
          onChange={this.onEmailInputChange}
          value={this.state.email}
          disabled={this.state.submitted}
        />
        <Button size='large' type='submit'fluid loading={this.state.submitted}>
          Send Request Email
        </Button>
        <Link to='/login/' className='back-link'>Go back to Login</Link>
      </Form>
    )
  }
}

export default ForgetPasswordForm
