import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';

class APIManagement extends Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  render() {
    return (
      <div>
        <h1>
          APIManagement
        </h1>
      </div>
    );
  }
}

APIManagement.defaultProps = {};

APIManagement.propTypes = {};

export default withRouter(APIManagement);
