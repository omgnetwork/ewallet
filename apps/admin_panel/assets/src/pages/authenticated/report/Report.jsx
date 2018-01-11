import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';

class Report extends Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  render() {
    return (
      <div>
        <h1>
          Report
        </h1>
      </div>
    );
  }
}

Report.defaultProps = {};

Report.propTypes = {};

export default withRouter(Report);
