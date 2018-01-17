import React from 'react';
import PropTypes from 'prop-types';
import FA from 'react-fontawesome';

const defaultProps = {
  faName: 'camera',
  className: '',
  onClick: () => {},
  size: 'medium',
  show: true,
};

const propTypes = {
  className: PropTypes.string,
  faName: PropTypes.string,
  onClick: PropTypes.func,
  show: PropTypes.bool,
  size: PropTypes.oneOf(['small', 'medium']),
};

const OMGCircleButton = ({
  faName, className, onClick, size, show,
}) => (
  <button
    className={`omg_circle_button__${size} ${className}`}
    onClick={onClick}
    style={{ display: show ? 'inline' : 'none' }}
    type="button"
  >
    <FA name={faName} />
  </button>
);

OMGCircleButton.propTypes = propTypes;

OMGCircleButton.defaultProps = defaultProps;

export default OMGCircleButton;
