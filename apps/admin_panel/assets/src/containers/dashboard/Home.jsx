import React, { Component } from "react";
import { connect } from "react-redux";
import { withRouter } from "react-router-dom";

import { userActions } from "../../actions";
import { Button } from 'react-bootstrap';

class Home extends Component {

  constructor(props) {
    super(props);

    this.handleClickLogout = this.handleClickLogout.bind(this);
  }

  handleClickLogout(e) {
    e.preventDefault();
    this.props.dispatch(userActions.logout());
  }

  render() {
    const { loggingOut } = this.props;
    return(
      <div>
        <p> This is the home page </p>
        <Button onClick={this.handleClickLogout}>
          Logout
        </Button>
      </div>
    );
  }

}

function mapStateToProps(state) {
  const { loggingOut } = state.authentication;
  return {
    loggingOut
  };
}

export default withRouter(connect(mapStateToProps)(Home));
