import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';

class Tokens extends Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  render() {
    return (
      <div>
        <h1>
          Tokens
        </h1>
      </div>
    );
  }
}

Tokens.defaultProps = {};

Tokens.propTypes = {};

export default withRouter(Tokens);
