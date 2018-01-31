import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Button } from 'react-bootstrap';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';

import Actions from './actions';
import OMGFieldGroup from '../../../components/OMGFieldGroup';
import OMGLoadingButton from '../../../components/OMGLoadingButton';

class UpdatePasswordForm extends Component {
  constructor(props) {
    super(props);
    const { history, isReset } = props;
    const { email, resetToken } = isReset
      ? Actions.processURLResetPWParams(history.location)
      : Actions.processURLInvitationParams(history.location);
    if (!(email && resetToken)) {
      history.push('/signin');
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
    const {
      password,
      passwordConfirmation,
      resetToken,
      email,
    } = this.state;
    const {
      createNewAdmin, updatePassword, onSuccess, isReset,
    } = this.props;
    if (password && resetToken && email) {
      if (isReset) {
        updatePassword({
          password, passwordConfirmation, resetToken, email,
        }, onSuccess);
      } else {
        createNewAdmin({
          password, passwordConfirmation, resetToken, email,
        }, onSuccess);
      }
    }
  }

  render() {
    const {
      loading, translate, history, submitText, title,
    } = this.props;
    const { password, passwordConfirmation, email } = this.state;
    return (
      <div className="omg-form">
        <h2 className="omg-form__title">
          {title}
        </h2>
        <h3 className="omg-form__subtitle">
          {translate('update-password.email')}
        </h3>
        <h3 className="omg-form__subtitle">
          {email}
        </h3>
        <form autoComplete="off" onSubmit={this.handleSubmit}>
          <OMGFieldGroup
            help={translate('update-password.password.help')}
            id="password"
            label={translate('update-password.password.label')}
            onChange={this.handleChange}
            type="password"
            validationState={this.getPasswordValidationState()}
            value={password}
          />
          <OMGFieldGroup
            help={translate('update-password.password_confirmation.help')}
            id="passwordConfirmation"
            label={translate('update-password.password_confirmation.label')}
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
                {submitText}
              </OMGLoadingButton>
              <Button
                bsStyle="link"
                className="link-omg-blue"
                disabled={loading}
                onClick={() => { history.push('/signin'); }}
              >
                {translate('update-password.cancel')}
              </Button>
            </span>
          </div>
        </form>
      </div>
    );
  }
}

UpdatePasswordForm.propTypes = {
  createNewAdmin: PropTypes.func.isRequired,
  history: PropTypes.object.isRequired,
  isReset: PropTypes.bool,
  loading: PropTypes.bool.isRequired,
  onSuccess: PropTypes.func.isRequired,
  submitText: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  translate: PropTypes.func.isRequired,
  updatePassword: PropTypes.func.isRequired,
};

UpdatePasswordForm.defaultProps = {
  isReset: false,
};

function mapStateToProps(state) {
  const { loading } = state.global;
  const translate = getTranslate(state.locale);
  const isReset = state.router.location.pathname === '/update_password';
  return {
    loading,
    translate,
    isReset,
  };
}

function mapDispatchToProps(dispatch) {
  return {
    updatePassword: (params, onSuccess) => dispatch(Actions.updatePassword(params, onSuccess)),
    createNewAdmin: (params, onSuccess) => dispatch(Actions.createNewAdmin(params, onSuccess)),
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(UpdatePasswordForm));
