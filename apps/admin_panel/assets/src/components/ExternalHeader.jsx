import React, { Component } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";

class ExternalHeader extends Component {
  render() {
    const { authenticated } = this.props
    return (
      <div className="external-header">
        <ul>
          {!authenticated ? (
            <p>Please login to continue</p>
          ) : (
            <p>Welcome</p>
          )}
        </ul>
      </div>
    );
  }
}
ExternalHeader.propTypes = {
  authenticated: PropTypes.bool.isRequired
};

export default ExternalHeader;
