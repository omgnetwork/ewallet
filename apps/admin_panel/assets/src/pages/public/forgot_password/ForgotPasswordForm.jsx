import React, { Component } from 'react';
import { connect } from 'react-redux';
import { Button } from 'react-bootstrap';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';

import Actions from './actions';
import OMGFieldGroup from '../../../components/OMGFieldGroup';
import OMGLoadingButton from '../../../components/OMGLoadingButton';
import { OMISEGO_BASE_URL } from '../../../omisego/config';
import { onInputChange, onSubmit, getEmailValidationState, isFormValid } from './stateFunctions';

class ForgotPasswordForm extends Component {
  constructor(props) {
    super(props);
    this.state = {
      email: '',
      submitted: false, //eslint-disable-line
      didModifyEmail: false, //eslint-disable-line
    };

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  handleChange(e) {
    const { target } = e;
    this.setState(onInputChange(target));
  }

  handleSubmit(e) {
    e.preventDefault();
    this.setState(onSubmit());
    const { email } = this.state;
    const { forgotPassword, onSuccess } = this.props;
    if (email) {
      forgotPassword({ email, url: OMISEGO_BASE_URL }, onSuccess);
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
            validationState={getEmailValidationState(this.state)}
            value={email}
          />
          <div>
            <span>
              <OMGLoadingButton
                disabled={!isFormValid(this.state)}
                loading={loading}
                type="submit"
              >
                {translate('forgot-password.reset_your_password')}
              </OMGLoadingButton>
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
    forgotPassword: (params, onSuccess) => dispatch(Actions.forgotPassword(params, onSuccess)),
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(ForgotPasswordForm));
