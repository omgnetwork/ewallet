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

Alerter.defaultProps = {
  alert: {
    type: 'alert-danger',
    message: 'alert.message should not be empty!',
  },
};

Alerter.propTypes = {
  alert: PropTypes.shape({
    type: PropTypes.oneOf(['alert-success', 'alert-danger']),
    message: PropTypes.string,
  }),
};

export default Alerter;
