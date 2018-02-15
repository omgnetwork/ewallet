import React, { Component } from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { Button } from 'react-bootstrap';
import PropTypes from 'prop-types';
import Actions from '../header/actions';

class Home extends Component {
  constructor(props) {
    super(props);

    this.handleClickLogout = this.handleClickLogout.bind(this);
  }

  handleClickLogout() {
    const { logout } = this.props;
    logout();
  }

  render() {
    const { loading } = this.props; // eslint-disable-line no-unused-vars
    return (
      <div>
        <Button onClick={this.handleClickLogout}>
          Logout
        </Button>
      </div>
    );
  }
}

Home.propTypes = {
  loading: PropTypes.bool.isRequired,
  logout: PropTypes.func.isRequired,
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
