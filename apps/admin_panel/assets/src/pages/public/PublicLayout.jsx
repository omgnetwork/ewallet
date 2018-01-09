import React from 'react';
import { connect } from 'react-redux';

import PropTypes from 'prop-types';
import PublicHeader from './PublicHeader';
import PublicFooter from './PublicFooter';
import Alerter from '../../components/Alerter';

const PublicLayout = ({ alert, children }) => (
  <div className="row">
    <div className="col-xs-12 col-sm-8 col-sm-offset-2 col-lg-6 col-lg-offset-3">
      <div className="public-layout">
        <PublicHeader />
        <div className="public-container">
          <Alerter alert={alert} />
          {children}
        </div>
        <PublicFooter />
      </div>
    </div>
  </div>
);

PublicLayout.propTypes = {
  alert: PropTypes.object.isRequired,
  children: PropTypes.element.isRequired,
};

function mapStateToProps(state) {
  const { alert } = state;
  return {
    alert,
  };
}

export default connect(mapStateToProps)(PublicLayout);
