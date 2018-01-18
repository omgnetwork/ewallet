import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Button } from 'react-bootstrap';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';

import Actions from './actions';
import OMGFieldGroup from '../../../components/OMGFieldGroup';

class ForgotPasswordForm extends Component {
  constructor(props) {
    super(props);
    this.state = {
      email: '',
      submitted: false,
      didModifyEmail: false,
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  getEmailValidationState() {
    const { submitted, didModifyEmail } = this.state;
    return !this.isEmailValid() && (submitted || didModifyEmail) ? 'error' : null;
  }

  isEmailValid() {
    const { email } = this.state;
    return /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,})+$/.test(email);
  }

  isFormValid() {
    return this.isEmailValid();
  }

  handleChange(e) {
    const { id, value } = e.target;
    this.setState((prevState) => {
      let { didModifyEmail } = prevState;
      didModifyEmail = true;
      return {
        [id]: value,
        didModifyEmail,
      };
    });
  }

  handleSubmit(e) {
    e.preventDefault();
    this.setState({ submitted: true });
    const { email } = this.state;
    const { forgotPassword, onSuccess } = this.props;
    if (email) {
      forgotPassword({ email }, onSuccess);
    }
  }

  render() {
    const { loading, translate, history } = this.props;
    const { email } = this.state;
    return (
      <div className="omg-form">
        <h2 className="omg-form__title">
          {translate('forgot-password.forgot_password')}
        </h2>
        <h3 className="omg-form__subtitle">
          {translate('forgot-password.enter_your_email')}
        </h3>
        <form autoComplete="off" onSubmit={this.handleSubmit}>
          <OMGFieldGroup
            help={translate('forgot-password.email.help')}
            id="email"
            label={translate('forgot-password.email.label')}
            onChange={this.handleChange}
            type="text"
            validationState={this.getEmailValidationState()}
            value={email}
          />
          <div>
            <span>
              <Button
                bsClass="btn btn-omg-blue"
                bsStyle="primary"
                disabled={loading || !this.isFormValid()}
                type="submit"
              >
                {loading ? translate('global.loading') : translate('forgot-password.reset_your_password')}
              </Button>
              <span className="ml-1">
                {translate('forgot-password.or')}
              </span>
              <Button
                bsStyle="link"
                className="link-omg-blue"
                disabled={loading}
                onClick={() => { history.push('/signin'); }}
              >
                {translate('forgot-password.sign_in')}
              </Button>
            </span>
          </div>
        </form>
      </div>
    );
  }
}

ForgotPasswordForm.propTypes = {
  forgotPassword: PropTypes.func.isRequired,
  history: PropTypes.object.isRequired,
  loading: PropTypes.bool.isRequired,
  onSuccess: PropTypes.func.isRequired,
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
    forgotPassword: (email, onSuccess) => dispatch(Actions.forgotPassword(email, onSuccess)),
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ForgotPasswordForm));
