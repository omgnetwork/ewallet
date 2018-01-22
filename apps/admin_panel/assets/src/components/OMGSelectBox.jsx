import React, { Component } from 'react';
import PropTypes from 'prop-types';
import OMGFieldGroup from './OMGFieldGroup';

class OMGSelectBox extends Component {
  constructor(props) {
    super(props);
    const { defaultValue } = props;
    this.state = {
      select: defaultValue,
    };
    this.handleChanged = this.handleChanged.bind(this);
  }

  handleChanged(e) {
    const { value } = e.target;
    const { onOptionChanged } = this.props;
    this.setState(
      {
        select: value,
      },
      () => {
        const { select } = this.state;
        onOptionChanged(select);
      },
    );
  }

  render() {
    const { select } = this.state;
    const { options } = this.props;
    const selectOptions = options.map((v, index) => (
      <option key={index} value={v}>
        {v}
      </option>
    ));

    const { label, id, help } = this.props;
    return (
      <OMGFieldGroup
        componentClass="select"
        help={help}
        id={id}
        inputClass="omg-select-box__input"
        label={label}
        onChange={this.handleChanged}
        selectOptions={selectOptions}
        validationState={null}
        value={select}
      />
    );
  }
}

OMGSelectBox.propTypes = {
  defaultValue: PropTypes.string,
  help: PropTypes.string,
  id: PropTypes.string,
  label: PropTypes.string.isRequired,
  onOptionChanged: PropTypes.func.isRequired,
  options: PropTypes.arrayOf(PropTypes.string),
};

OMGSelectBox.defaultProps = {
  id: 'omg-select-box',
  options: ['Loading...'],
  defaultValue: 'Loading...',
  help: '',
};

export default OMGSelectBox;
