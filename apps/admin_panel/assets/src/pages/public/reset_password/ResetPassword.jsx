import React, { Component } from 'react';
import { connect } from 'react-redux';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';
import ResetPasswordForm from './ResetPasswordForm';
import ResetPasswordSuccess from './ResetPasswordSuccess';

class ResetPassword extends Component {
  constructor(props) {
    super(props);
    this.state = { didReset: false };
    const { translate, pathname } = props;
    const isReset = pathname === '/reset_password';
    this.text = {
      title: isReset
        ? translate('reset-password.reset_your_password')
        : translate('confirm-email.setup_password'),
      submit: isReset
        ? translate('reset-password.reset_password')
        : translate('confirm-email.submit'),
      success: isReset
        ? translate('reset-password-success.reset_password_complete')
        : translate('confirm-email.success'),
    };
  }

  render() {
    const { didReset } = this.state;
    const { submit, success, title } = this.text;
    return (
      didReset
        ? <ResetPasswordSuccess successText={success} />
        : <ResetPasswordForm
          onSuccess={() => { this.setState({ didReset: true }); }}
          submitText={submit}
          title={title}
        />
    );
  }
}

ResetPassword.propTypes = {
  pathname: PropTypes.string.isRequired,
  translate: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const translate = getTranslate(state.locale);
  const { pathname } = state.router.location;
  return {
    pathname,
    translate,
  };
}

export default connect(mapStateToProps, null)(ResetPassword);
