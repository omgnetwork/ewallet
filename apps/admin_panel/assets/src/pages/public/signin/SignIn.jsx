import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Button } from 'react-bootstrap';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';

import Actions from './actions';
import OMGFieldGroup from '../../../components/OMGFieldGroup';
import OMGLoadingButton from '../../../components/OMGLoadingButton';

class SignIn extends Component {
  constructor(props) {
    super(props);
    this.state = {
      email: '',
      password: '',
      submitted: false,
      didModifyEmail: false,
      didModifyPassword: false,
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  getEmailValidationState() {
    const { submitted, didModifyEmail } = this.state;
    return !this.isEmailValid() && (submitted || didModifyEmail) ? 'error' : null;
  }

  getPasswordValidationState() {
    const { submitted, didModifyPassword } = this.state;
    return !this.isPasswordValid() && (submitted || didModifyPassword) ? 'error' : null;
  }

  isEmailValid() {
    const { email } = this.state;
    return /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,})+$/.test(email);
  }

  isPasswordValid() {
    const { password } = this.state;
    return password.length >= 8;
  }

  isFormValid() {
    return this.isEmailValid() && this.isPasswordValid();
  }

  handleChange(e) {
    const { id, value } = e.target;
    this.setState((prevState) => {
      let { didModifyEmail, didModifyPassword } = prevState;
      if (id === 'email') {
        didModifyEmail = true;
      } else if (id === 'password') {
        didModifyPassword = true;
      }
      return {
        [id]: value,
        didModifyEmail,
        didModifyPassword,
      };
    });
  }

  handleSubmit(e) {
    e.preventDefault();
    this.setState({ submitted: true });
    const { email, password } = this.state;
    const { login } = this.props;
    if (email && password) {
      login({ email, password });
    }
  }

  render() {
    const { loading, translate, history } = this.props;
    const { email, password } = this.state;
    return (
      <div className="omg-form">
        <h2 className="omg-form__title">
          {translate('sign-in.sign-in')}
        </h2>
        <form autoComplete="off" onSubmit={this.handleSubmit}>
          <OMGFieldGroup
            help={translate('sign-in.email.help')}
            id="email"
            label={translate('sign-in.email.label')}
            onChange={this.handleChange}
            type="text"
            validationState={this.getEmailValidationState()}
            value={email}
          />
          <OMGFieldGroup
            help={translate('sign-in.password.help')}
            id="password"
            label={translate('sign-in.password.label')}
            onChange={this.handleChange}
            type="password"
            validationState={this.getPasswordValidationState()}
            value={password}
          />
          <div>
            <span>
              <OMGLoadingButton
                disabled={!this.isFormValid()}
                loading={loading}
                type="submit"
              >
                {translate('sign-in.sign-in')}
              </OMGLoadingButton>
              <span className="ml-1">
                {translate('sign-in.or')}
              </span>
              <Button
                bsStyle="link"
                className="link-omg-blue"
                disabled={loading}
                onClick={() => { history.push('/forgot_password'); }}
              >
                {translate('sign-in.forgot_password')}
              </Button>
            </span>
          </div>
        </form>
      </div>
    );
  }
}

SignIn.propTypes = {
  history: PropTypes.object.isRequired,
  loading: PropTypes.bool.isRequired,
  login: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const { loading } = state.global;
  const translate = getTranslate(state.locale);
  return {
    loading,
    translate,
  };
}

function mapDispatchToProps(dispatch) {
  return {
    login: params => dispatch(Actions.login(params)),
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(SignIn));
