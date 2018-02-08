import React from 'react';
import { connect } from 'react-redux';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';
import { withRouter, Link } from 'react-router-dom';

const ResetPasswordSuccess = ({ translate }) => (
  <div className="omg-form">
    <h2 className="omg-form__title">
      {translate('reset-password-success.update_password_complete')}
    </h2>
    <h3 className="omg-form__subtitle">
      {translate('reset-password-success.please_check_your_email')}
    </h3>
    <Link
      className="link-omg-blue btn btn-link"
      href="/signin"
      to="/signin"
    >
      {translate('reset-password-success.back_to_sign_in')}
    </Link>
  </div>
);


ResetPasswordSuccess.propTypes = {
  translate: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const translate = getTranslate(state.locale);
  return {
    translate,
  };
}

export default withRouter(connect(mapStateToProps)(ResetPasswordSuccess));
