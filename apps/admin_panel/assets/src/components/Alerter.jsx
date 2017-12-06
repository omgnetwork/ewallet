import React, { Component } from "react";

class Alerter extends Component {
  render() {
    const { alert } = this.props
    return (
      <div className="alert">
        {alert.message ? (
          <div className={`alert ${alert.type}`}>
            {alert.message}
          </div>
        ) : ( null )}
      </div>
    );
  }
}

export default Alerter;
