import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { getTranslate } from 'react-localize-redux';
import Actions from './action';
import { LOADING_GIF } from '../../../src/config';

class Startup extends Component {
  static shouldLoad(newProps) {
    const { session } = newProps;
    return (!session.isSyncing && !session.isSynced);
  }

  constructor(props) {
    super(props);
    this.gif = LOADING_GIF.length === 1
      ? LOADING_GIF[0]
      : LOADING_GIF[Math.floor(Math.random() * 100) % LOADING_GIF.length];
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
    const { session, children, translate } = this.props;
    if (session.isSynced) { return children; }
    return (
      <div className="fh omg-center">
        <div>
          <img alt="Loading" src={this.gif} />
          <p className="omg-center mt-1">
            {translate('global.loading_gif_quote')}
          </p>
        </div>
      </div>
    );
  }
}

function mapStateToProps(state) {
  const { session } = state;
  const translate = getTranslate(state.locale);
  return { session, translate };
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
  translate: PropTypes.func.isRequired,
};

export default connect(
  mapStateToProps,
  mapDispatchToProps,
)(Startup);
