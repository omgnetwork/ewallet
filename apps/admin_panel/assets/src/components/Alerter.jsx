import React from 'react';
import PropTypes from 'prop-types';

const Alerter = ({ alert }) => (
  <div>
    {alert.message ? (
      <div className={`alert ${alert.type}`}>
        {alert.message}
      </div>
    ) : (null)}
  </div>
);

Alerter.propTypes = {
  alert: PropTypes.object.isRequired,
};

export default Alerter;
