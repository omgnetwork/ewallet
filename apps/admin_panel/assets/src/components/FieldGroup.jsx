import React from 'react';
import PropTypes from 'prop-types';
import { FormGroup, ControlLabel, FormControl, HelpBlock } from 'react-bootstrap';

const FieldGroup = ({
  id, label, help, validationState, groupClass, labelClass, inputClass, ...rest
}) => (
  <FormGroup className={groupClass} controlId={id} validationState={validationState}>
    <ControlLabel className={labelClass}>
      {label}
    </ControlLabel>
    <FormControl className={inputClass} {...rest} />
    {help && validationState === 'error' &&
    <HelpBlock>
      {help}
    </HelpBlock>}
  </FormGroup>
);

FieldGroup.propTypes = {
  groupClass: PropTypes.string.isRequired,
  help: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  inputClass: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  labelClass: PropTypes.string.isRequired,
  validationState: PropTypes.string,
};

FieldGroup.defaultProps = {
  validationState: '',
};


export default FieldGroup;
