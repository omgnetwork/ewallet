import React, { Component } from 'react';
import { connect } from 'react-redux';

import ForgotPasswordForm from './ForgotPasswordForm';
import ForgotPasswordSuccess from './ForgotPasswordSuccess';

class ForgotPassword extends Component {
  constructor() {
    super();
    this.state = { didReset: false };
  }

  render() {
    const { didReset } = this.state;
    return (
      (didReset && <ForgotPasswordSuccess />) ||
      <ForgotPasswordForm onSuccess={() => { this.setState({ didReset: true }); }} />
    );
  }
}

export default connect()(ForgotPassword);
