import React from 'react';
import PropTypes from 'prop-types';
import FieldGroup from './FieldGroup';

const OMGFieldGroup = ({
  groupClass, inputClass, labelClass, ...props
}) => (
  <FieldGroup {...props} groupClass={groupClass} inputClass={inputClass} labelClass={labelClass} />
);

OMGFieldGroup.propTypes = {
  groupClass: PropTypes.string,
  inputClass: PropTypes.string,
  labelClass: PropTypes.string,
};

OMGFieldGroup.defaultProps = {
  groupClass: 'omg-form__group',
  inputClass: 'omg-form__input',
  labelClass: 'omg-form__label',
};

export default OMGFieldGroup;
