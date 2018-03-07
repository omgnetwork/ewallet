import React, { Component } from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { Button } from 'react-bootstrap';
import PropTypes from 'prop-types';
import Actions from './actions';

class Home extends Component {
  constructor(props) {
    super(props);

    this.handleClickLogout = this.handleClickLogout.bind(this);
  }

  handleClickLogout(e) {
    this.props.logout();
  }

  render() {
    const { loading } = this.props; // eslint-disable-line no-unused-vars
    return (
      <div>
        <p> This is the home page </p>
        <Button onClick={this.handleClickLogout}>Logout</Button>
      </div>
    );
  }
}

Home.propTypes = {
  logout: PropTypes.func.isRequired,
  loading: PropTypes.bool.isRequired,
};

function mapStateToProps(state) {
  const { loading } = state.global;
  return {
    loading,
  };
}

function mapDispatchToProps(dispatch) {
  return {
    logout: () => dispatch(Actions.logout()),
  };
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Home));
