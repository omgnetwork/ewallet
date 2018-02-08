import React from 'react';
import { connect } from 'react-redux';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';
import { withRouter, Link } from 'react-router-dom';

const ResetPasswordSuccess = ({ successText, translate }) => (
  <div className="omg-form">
    <h2 className="omg-form__title">
      {successText}
    </h2>
    <Link
      className="link-omg-blue btn btn-link"
      href="/signin"
      to="/signin"
    >
      {translate('update-password-success.back_to_sign_in')}
    </Link>
  </div>
);


ResetPasswordSuccess.propTypes = {
  successText: PropTypes.string.isRequired,
  translate: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const translate = getTranslate(state.locale);
  return {
    translate,
  };
}

export default withRouter(connect(mapStateToProps)(ResetPasswordSuccess));
