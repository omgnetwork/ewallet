import React from 'react';
import PropTypes from 'prop-types';

const Alerter = ({ alert }) => (
  <div className="alert-center">
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
    type: PropTypes.oneOf(['alert-success', 'alert-danger', 'alert-info']),
    message: PropTypes.string,
  }),
};

export default Alerter;
