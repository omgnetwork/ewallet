import React, { Component } from "react";
import { FormGroup, ControlLabel, FormControl, HelpBlock } from 'react-bootstrap';

class FieldGroup extends Component {

  render() {
    const { id, label, help, validationState, groupClass, labelClass, inputClass, ...rest } = this.props
    return(
      <FormGroup controlId={id} validationState={validationState} className={groupClass}>
        <ControlLabel className={labelClass}>{label}</ControlLabel>
        <FormControl className={inputClass} {...rest} />
        {help && validationState === "error" && <HelpBlock>{help}</HelpBlock>}
      </FormGroup>
    );
  }

}

export default FieldGroup
