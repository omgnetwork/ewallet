import React, { Component } from 'react'
import styled from 'styled-components'
import { Input, Button, Checkbox } from '../omg-uikit'
import { Link, withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import { compose } from 'recompose'
import { connect } from 'react-redux'
import { login } from '../omg-session/action'
const Form = styled.form`
  text-align: left;
  input {
    margin-top: 50px;
  }
  button {
    font-size: 16px;
  }
`
const OptionRowContainer = styled.div`
  display: flex;
  margin-top: 30px;
  align-items: center;
`
const OptionItem = styled.div`
  flex: 1 1 auto;
  text-align: ${props => props.align};
  color: ${props => props.theme.colors.B100};
  cursor: pointer;
  align-items: center;
  user-select: none;
  span {
    vertical-align: middle;
  }
`
const Error = styled.div`
  color: ${props => props.theme.colors.R400};
  text-align: center;
  padding: 10px 0;
  overflow: hidden;
  max-height: ${props => (props.error ? '50px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
`

class LoginForm extends Component {
  static propTypes = {
    history: PropTypes.object
  }
  state = {
    email: '',
    emailError: false,
    password: '',
    passwordError: false
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
    const passwordError = this.validatePassword(this.state.password)
    const submitted = !emailError && !passwordError
    this.setState({ emailError, passwordError, submitted })
    if (submitted) {
      try {
        const result = await this.props.login({
          email: this.state.email,
          password: this.state.password,
          rememberMe: this.state.rememberMe
        })
        if (result.data.success) {
          this.setState({ error: null })
          const redirectUrl = _.get(this.props, 'location.state.from.pathname')
          this.props.history.push(redirectUrl || `/${result.data.data.account_id}/dashboard`)
        } else {
          this.setState({ error: result.data.data.description, submitted: false })
        }
      } catch (error) {
        this.setState({ error: 'Something went wrong :(', submitted: false })
      }
    }
  }
  onEmailInputChange = e => {
    const value = e.target.value
    this.setState({ email: value, emailError: this.state.submitted && this.validateEmail(value) })
  }
  onPasswordInputChange = e => {
    const value = e.target.value
    this.setState({
      password: value,
      passwordError: this.state.submitted && this.validatePassword(value)
    })
  }
  onClickCheckbox = () => {
    this.setState(({ rememberMe }) => ({ rememberMe: !rememberMe }))
  }
  render () {
    return (
      <Form onSubmit={this.onSubmit} noValidate>
        <Input
          placeholder='Email'
          error={this.state.emailError}
          errorText='Invalid email'
          onChange={this.onEmailInputChange}
          value={this.state.email}
          disabled={this.state.submitted}
          name='email'
          autoComplete='off'
        />
        <Input
          placeholder='Password'
          type='password'
          error={this.state.passwordError}
          errorText='Field is required'
          onChange={this.onPasswordInputChange}
          value={this.state.password}
          disabled={this.state.submitted}
          name='password'
          autoComplete='off'
        />
        <OptionRowContainer>
          {/* <OptionItem align='left' onClick={this.onClickCheckbox}>
            <Checkbox checked={this.state.rememberMe} label={'Remember Me'} />
          </OptionItem> */}
          <OptionItem align='right'>
            <Link to='/forget-password/'>Forget Password ?</Link>
          </OptionItem>
        </OptionRowContainer>
        <Button size='large' type='submit' fluid loading={this.state.submitted}>
          Login
        </Button>
        <Error error={this.state.error}>{this.state.error}</Error>
      </Form>
    )
  }
}

const enhance = compose(connect(null, { login }), withRouter)

export default enhance(LoginForm)
