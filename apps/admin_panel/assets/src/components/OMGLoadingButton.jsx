import React from 'react';
import PropTypes from 'prop-types';
import { Button } from 'react-bootstrap';
import { getTranslate } from 'react-localize-redux';
import { connect } from 'react-redux';

const defaultProps = {
  className: 'btn-omg-blue',
  onClick: () => { },
  loading: false,
  disabled: false,
  type: 'button',
};

const propTypes = {
  children: PropTypes.string.isRequired,
  className: PropTypes.string,
  disabled: PropTypes.bool,
  loading: PropTypes.bool,
  onClick: PropTypes.func,
  translate: PropTypes.func.isRequired,
  type: PropTypes.string,
};

const OMGLoadingButton = ({
  children, className, disabled, onClick, loading, translate, type,
}) => (
  <Button
    bsClass={`btn ${className}`}
    bsStyle="primary"
    disabled={disabled || loading}
    onClick={onClick}
    type={type}
  >
    {loading ? translate('global.loading') : children }
  </Button>
);

OMGLoadingButton.propTypes = propTypes;

OMGLoadingButton.defaultProps = defaultProps;


function mapStateToProps(state) {
  const translate = getTranslate(state.locale);
  return {
    translate,
  };
}

export default connect(mapStateToProps, null)(OMGLoadingButton);
