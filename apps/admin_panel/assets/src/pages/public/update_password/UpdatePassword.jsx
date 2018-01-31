import React, { Component } from 'react';
import { connect } from 'react-redux';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';
import UpdatePasswordForm from './UpdatePasswordForm';
import UpdatePasswordSuccess from './UpdatePasswordSuccess';

class UpdatePassword extends Component {
  constructor(props) {
    super(props);
    this.state = { didReset: false };
    const { translate, pathname } = props;
    const isReset = pathname === '/update_password';
    this.text = {
      title: isReset
        ? translate('update-password.reset_your_password')
        : translate('confirm-email.setup_password'),
      submit: isReset
        ? translate('update-password.update_password')
        : translate('confirm-email.submit'),
      success: isReset
        ? translate('update-password-success.update_password_complete')
        : translate('confirm-email.success'),
    };
  }

  render() {
    const { didReset } = this.state;
    const { submit, success, title } = this.text;
    return (
      didReset
        ? <UpdatePasswordSuccess successText={success} />
        : <UpdatePasswordForm
          onSuccess={() => { this.setState({ didReset: true }); }}
          submitText={submit}
          title={title}
        />
    );
  }
}

UpdatePassword.propTypes = {
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

export default connect(mapStateToProps, null)(UpdatePassword);
