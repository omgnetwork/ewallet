import React, { Component } from "react";
import { connect } from "react-redux";

import PublicHeader from "../components/PublicHeader"
import PublicFooter from "../components/PublicFooter"
import Alerter from "../components/Alerter"

class PublicLayout extends Component {

  render() {
    const {alert} = this.props
    return (
      <div className="row">
        <div className="col-xs-12 col-sm-8 col-sm-offset-2 col-lg-6 col-lg-offset-3">
          <div className="public-layout">
            <PublicHeader />
            <div className="public-container">
              <Alerter alert={alert} />
              {this.props.children}
            </div>
            <PublicFooter />
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

export default connect(mapStateToProps)(PublicLayout);
