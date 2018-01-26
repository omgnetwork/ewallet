import React from 'react';
import { connect } from 'react-redux';

import PropTypes from 'prop-types';
import Alerter from '../../components/Alerter';
import Header from './Header';
import Sidebar from './Sidebar';

const AuthenticatedLayout = ({ alert, children }) => (
  <div className="fh">
    <Header />
    <div className="fh">
      <div className="col-md-3 authenticated-layout__sidebar">
        <Sidebar />
      </div>
      <div className="col-md-9 col-md-offset-3 authenticated-layout__main">
        <Alerter alert={alert} />
        {children}
      </div>
    </div>
  </div>
);

AuthenticatedLayout.propTypes = {
  alert: PropTypes.object.isRequired,
  children: PropTypes.element.isRequired,
};

function mapStateToProps(state) {
  const { alert } = state;
  return {
    alert,
  };
}

export default connect(mapStateToProps)(AuthenticatedLayout);
