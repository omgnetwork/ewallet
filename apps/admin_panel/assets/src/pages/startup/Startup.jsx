import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import Actions from './action';

class Startup extends Component {
  static shouldLoad(newProps) {
    const { session } = newProps;
    return (!session.isSyncing && !session.isSynced);
  }

  componentDidMount() {
    this.loadSessionIfNeededWithProps(this.props);
  }

  componentWillReceiveProps(nextProps) {
    this.loadSessionIfNeededWithProps(nextProps);
  }

  loadSessionIfNeededWithProps(props) {
    if (Startup.shouldLoad(props)) {
      const { loadSession } = this.props;
      loadSession();
    }
  }

  render() {
    const { session, children } = this.props;
    if (session.isSynced) { return children; }
    return (
      <p>
        Loading...
      </p>
    );
  }
}

function mapStateToProps(state) {
  const { session } = state;
  return { session };
}

function mapDispatchToProps(dispatch) {
  return {
    loadSession: () => dispatch(Actions.loadSession()),
  };
}

Startup.defaultProps = {
  children: {},
};

Startup.propTypes = {
  children: PropTypes.object,
  loadSession: PropTypes.func.isRequired,
  session: PropTypes.object.isRequired,
};

export default connect(
  mapStateToProps,
  mapDispatchToProps,
)(Startup);
