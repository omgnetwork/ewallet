import React from 'react';
import { connect } from 'react-redux';

import PropTypes from 'prop-types';
import PublicHeader from './PublicHeader';
import PublicFooter from './PublicFooter';
import Alerter from '../../components/Alerter';

const PublicLayout = ({ alert, children }) => (
  <div>
    <div className="public-layout">
      <div>
        <PublicHeader />
        <div className="public-layout__content">
          <Alerter alert={alert} />
          <div>
            <div>
              {children}
            </div>
          </div>
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
