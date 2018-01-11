import React, { Component } from 'react';
import { withRouter } from 'react-router-dom';

class Setting extends Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  render() {
    return (
      <div>
        <h1>
          Setting
        </h1>
      </div>
    );
  }
}

Setting.defaultProps = {};

Setting.propTypes = {};

export default withRouter(Setting);
