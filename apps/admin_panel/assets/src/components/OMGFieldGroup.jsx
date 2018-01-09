import React from 'react';
import FieldGroup from './FieldGroup';

const OMGFieldGroup = props => (
  <FieldGroup
    {...props}
    groupClass="omg-form__group"
    inputClass="omg-form__input"
    labelClass="omg-form__label"
  />
);

export default OMGFieldGroup;
