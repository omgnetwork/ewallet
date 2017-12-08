import React, { Component } from "react";
import { connect } from "react-redux";

import Alerter from "../components/Alerter"

class AuthenticatedLayout extends Component {

  render() {
    const {alert} = this.props
    return (
      <div>
        <Alerter alert={alert} />
        {this.props.children}
      </div>
    );
  }
}

function mapStateToProps(state) {
  const { alert } = state;
  return {
    alert
  };
}

export default connect(mapStateToProps)(AuthenticatedLayout);
