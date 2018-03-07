import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Button } from 'react-bootstrap';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';

import Actions from './actions';
import OMGFieldGroup from '../../../components/OMGFieldGroup';
import OMGLoadingButton from '../../../components/OMGLoadingButton';

class ResetPasswordForm extends Component {
  constructor(props) {
    super(props);
    const { history } = props;
    const { email, resetToken } = Actions.processURLParams(history.location);
    if (!(email && resetToken)) {
      history.push('/sigin');
    }
    this.state = {
      email,
      password: '',
      passwordConfirmation: '',
      resetToken,
      submitted: false,
      didModifyPassword: false,
      didModifyPasswordConfimation: false,
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  getPasswordValidationState() {
    const { submitted, didModifyPassword } = this.state;
    return !this.isPasswordValid() && (submitted || didModifyPassword) ? 'error' : null;
  }

  getPasswordConfirmationValidationState() {
    const { didModifyPasswordConfimation } = this.state;
    return !this.isPasswordConfirmationValid() && didModifyPasswordConfimation ? 'error' : null;
  }

  isPasswordValid() {
    const { password } = this.state;
    return password.length >= 8;
  }

  isPasswordConfirmationValid() {
    const { password, passwordConfirmation } = this.state;
    return password === passwordConfirmation;
  }

  isFormValid() {
    return this.isPasswordValid() && this.isPasswordConfirmationValid();
  }

  handleChange(e) {
    const { id, value } = e.target;
    this.setState((prevState) => {
      let { didModifyPassword, didModifyPasswordConfimation } = prevState;
      if (id === 'password') {
        didModifyPassword = true;
      } else if (id === 'passwordConfirmation') {
        didModifyPasswordConfimation = true;
      }
      return {
        [id]: value,
        didModifyPassword,
        didModifyPasswordConfimation,
      };
    });
  }

  handleSubmit(e) {
    e.preventDefault();
    this.setState({ submitted: true });
    const { password, resetToken, email } = this.state;
    const { resetPassword, onSuccess } = this.props;
    if (password && resetToken && email) {
      resetPassword({ password, resetToken, email }, onSuccess);
    }
  }

  render() {
    const { loading, translate, history } = this.props;
    const { password, passwordConfirmation, email } = this.state;
    return (
      <div className="omg-form">
        <h2 className="omg-form__title">
          {translate('reset-password.reset_your_password')}
        </h2>
        <h3 className="omg-form__subtitle">
          {translate('reset-password.email')}
        </h3>
        <h3 className="omg-form__subtitle">
          {email}
        </h3>
        <form autoComplete="off" onSubmit={this.handleSubmit}>
          <OMGFieldGroup
            help={translate('reset-password.password.help')}
            id="password"
            label={translate('reset-password.password.label')}
            onChange={this.handleChange}
            type="password"
            validationState={this.getPasswordValidationState()}
            value={password}
          />
          <OMGFieldGroup
            help={translate('reset-password.password_confirmation.help')}
            id="passwordConfirmation"
            label={translate('reset-password.password_confirmation.label')}
            onChange={this.handleChange}
            type="password"
            validationState={this.getPasswordConfirmationValidationState()}
            value={passwordConfirmation}
          />
          <div>
            <span>
              <OMGLoadingButton
                disabled={!this.isFormValid()}
                loading={loading}
                type="submit"
              >
                {translate('reset-password.reset_password')}
              </OMGLoadingButton>
              <Button
                bsStyle="link"
                className="link-omg-blue"
                disabled={loading}
                onClick={() => { history.push('/signin'); }}
              >
                {translate('reset-password.cancel')}
              </Button>
            </span>
          </div>
        </form>
      </div>
    );
  }
}

ResetPasswordForm.propTypes = {
  history: PropTypes.object.isRequired,
  loading: PropTypes.bool.isRequired,
  onSuccess: PropTypes.func.isRequired,
  resetPassword: PropTypes.func.isRequired,
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
    resetPassword: (params, onSuccess) => dispatch(Actions.resetPassword(params, onSuccess)),
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ResetPasswordForm));
