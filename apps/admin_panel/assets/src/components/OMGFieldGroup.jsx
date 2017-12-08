import React, { Component } from "react";
import FieldGroup from "./FieldGroup"

class OMGFieldGroup extends Component {

  render() {
    return(
      <FieldGroup {...this.props}
        groupClass="omg-form__group"
        labelClass="omg-form__label"
        inputClass="omg-form__input"
      />
    );
  }

}

export default OMGFieldGroup
