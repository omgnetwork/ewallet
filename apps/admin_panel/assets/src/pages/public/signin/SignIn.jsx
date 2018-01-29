import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Button } from 'react-bootstrap';
import { withRouter } from 'react-router-dom';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';

import Actions from './actions';
import OMGFieldGroup from '../../../components/OMGFieldGroup';
import OMGLoadingButton from '../../../components/OMGLoadingButton';
import {
  getEmailValidationState,
  getPasswordValidationState,
  isFormValid,
  onInputChange,
  onSubmit,
} from './stateFunctions';

class SignIn extends Component {
  constructor(props) {
    super(props);
    this.state = {
      email: '',
      password: '',
      submitted: false, //eslint-disable-line
      didModifyEmail: false, //eslint-disable-line
      didModifyPassword: false, //eslint-disable-line
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleChange(e) {
    const { target } = e;
    this.setState(prevState => (onInputChange(target, prevState)));
  }

  handleSubmit(e) {
    e.preventDefault();
    this.setState(onSubmit());
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
            validationState={getEmailValidationState(this.state)}
            value={email}
          />
          <OMGFieldGroup
            help={translate('sign-in.password.help')}
            id="password"
            label={translate('sign-in.password.label')}
            onChange={this.handleChange}
            type="password"
            validationState={getPasswordValidationState(this.state)}
            value={password}
          />
          <div>
            <span>
              <OMGLoadingButton
                disabled={!isFormValid(this.state)}
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
