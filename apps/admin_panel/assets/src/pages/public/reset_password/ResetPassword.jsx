import React, { Component } from 'react';
import { connect } from 'react-redux';

import ResetPasswordForm from './ResetPasswordForm';
import ResetPasswordSuccess from './ResetPasswordSuccess';

class ResetPassword extends Component {
  constructor() {
    super();
    this.state = { didReset: false };
  }

  render() {
    const { didReset } = this.state;
    return (
      didReset
        ? <ResetPasswordSuccess />
        : <ResetPasswordForm onSuccess={() => { this.setState({ didReset: true }); }} />
    );
  }
}

export default connect()(ResetPassword);
