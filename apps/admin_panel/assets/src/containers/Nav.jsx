import React, { Component } from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";

class Nav extends Component {
  render() {
    return (
      <div className="nav">
        <ul>
          <li><Link to='/'>Home</Link></li>
          <li>
            {!this.props.authenticated ? (
              <Link to='/login'>Login</Link>
            ) : (
              <Link to='/logout'>Logout</Link>
            )}
          </li>
        </ul>
      </div>
    );
  }
}
Nav.propTypes = {
  authenticated: PropTypes.bool.isRequired
};

export default Nav;
