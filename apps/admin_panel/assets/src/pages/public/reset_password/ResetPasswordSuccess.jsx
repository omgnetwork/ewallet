import React from 'react';
import { connect } from 'react-redux';
import { Button } from 'react-bootstrap';
import { getTranslate } from 'react-localize-redux';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';

const ForgotPasswordSuccess = ({ successText, translate, history }) => (
  <div className="omg-form">
    <h2 className="omg-form__title">
      {successText}
    </h2>
    <Button
      bsClass="btn btn-omg-blue"
      bsStyle="primary"
      onClick={() => { history.push('/signin'); }}
    >
      {translate('reset-password-success.back_to_sign_in')}
    </Button>
  </div>
);


ForgotPasswordSuccess.propTypes = {
  history: PropTypes.object.isRequired,
  successText: PropTypes.string.isRequired,
  translate: PropTypes.func.isRequired,
};

function mapStateToProps(state) {
  const translate = getTranslate(state.locale);
  return {
    translate,
  };
}

export default withRouter(connect(mapStateToProps)(ForgotPasswordSuccess));
