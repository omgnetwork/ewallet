import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';

class Transactions extends Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  render() {
    return (
      <div>
        <h1>
          Transactions
        </h1>
      </div>
    );
  }
}

Transactions.defaultProps = {};

Transactions.propTypes = {};

export default withRouter(Transactions);
