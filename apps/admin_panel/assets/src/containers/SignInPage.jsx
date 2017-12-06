import React from "react";
import { connect } from "react-redux";
import { withRouter } from "react-router-dom";
import { Button } from 'react-bootstrap';

import { userActions } from "../actions";
import Loader from "../components/Loader";
import FieldGroup from "../components/FieldGroup"

class SignInPage extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      username: "",
      password: "",
      submitted: false,
      didModifyUsername: false,
      didModifyPassword: false,
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleChange(e) {
    const { id, value } = e.target;
    var { didModifyUsername, didModifyPassword} = this.state
    if (id === "username") { didModifyUsername = true }
    else if (id === "password") { didModifyPassword = true }
    this.setState({ [id]: value,
                    didModifyUsername: didModifyUsername,
                    didModifyPassword: didModifyPassword
                  });
  }

  handleSubmit(e) {
    e.preventDefault();
    this.setState({ submitted: true });
    const { username, password } = this.state;
    const { dispatch } = this.props;
    if (username && password) {
      dispatch(userActions.login(username, password));
    }
  }

  isUsernameValid() {
    return this.state.username.length >= 3
  }

  isPasswordValid() {
    return this.state.password.length >= 8
  }

  isFormValid() {
    return this.isUsernameValid() && this.isPasswordValid()
  }

  getUsernameValidationState() {
    const { submitted, didModifyUsername } = this.state;
    return (!this.isUsernameValid() && (submitted || didModifyUsername)) ? "error" : null
  }

  getPasswordValidationState() {
    const { submitted, didModifyPassword } = this.state;
    return (!this.isPasswordValid() && (submitted || didModifyPassword)) ? "error" : null
  }

  render() {
    const { loggingIn } = this.props;
    const { username, password } = this.state;
    return (
      <section className="sign-in-form-container">
        <h2>Sign in</h2>
        <form onSubmit={this.handleSubmit}>
          <FieldGroup
            id="username"
            label="Username"
            help = "Username is required and should be at least 3 characters long"
            validationState={this.getUsernameValidationState()}
            placeholder="Username"
            type="text"
            value={username}
            onChange={this.handleChange}
          />
          <FieldGroup
            id="password"
            label="Password"
            help="Password is required and should be at least 8 characters long"
            validationState={this.getPasswordValidationState()}
            placeholder="Password"
            type="password"
            value={password}
            onChange={this.handleChange}
          />
          <Button bsStyle="primary"
                  disabled={loggingIn || !this.isFormValid()}
                  type="submit"
          >
            {loggingIn ? 'Loading...' : 'Sign In'}
          </Button>
        </form>
      </section>
    );
  }
}

function mapStateToProps(state) {
  const { loggingIn } = state.authentication;
  return {
    loggingIn
  };
}

export default withRouter(connect(mapStateToProps)(SignInPage));
