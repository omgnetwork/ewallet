import React, { Component } from "react";
import { connect } from "react-redux";

import Alerter from "../components/Alerter"
import Header from "../containers/authenticated/Header"
import Sidebar from "../containers/authenticated/Sidebar"

class AuthenticatedLayout extends Component {

  render() {
    const { alert } = this.props
    return (
      <div className="fh">
        <Header />
        <div className="row fh">
          <div className="col-md-3 authenticated-layout__sidebar fh">
            <Sidebar />
          </div>
          <div className="col-md-9 authenticated-layout__main fh">
            <Alerter alert={alert} />
            {this.props.children}
          </div>
        </div>
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
