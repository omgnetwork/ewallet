import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Select, { components } from 'react-select'

import Icon from '../icon'

const SelectStyled = styled(Select)`
  .react-select__control {
    border: none;
    border-bottom: 1px solid ${props => props.theme.colors.S400};
    box-shadow: none;
    border-radius: 0;
  }
  .react-select__control--is-focused,
  .react-select__control--menu-is-open {
    box-shadow: none;
    border-color: ${props => props.theme.colors.BL400};
  }
  .react-select__value-container {
    padding: 0;
    max-height: 38px;
    overflow: scroll;
  }
  .react-select__placeholder {
    color: ${props => props.theme.colors.S400};
    font-size: 12px;
  }
  .react-select__indicator {
    &:hover {
      cursor: pointer;
    }
    svg {
      height: 15px;
      width: 15px;
      color: ${props => props.theme.colors.S500};
    }
    i {
      color: ${props => props.theme.colors.S500};
      font-size: 12px;
    }
  }
  .react-select__multi-value {
    background-color: ${props => props.theme.colors.S100};
  }
  .react-select__multi-value__remove {
    transition: all 200ms ease-in-out;
    &:hover {
      cursor: pointer;
      color: white;
      background-color: ${props => props.theme.colors.BL400};
    }
  }
  .react-select__indicator-separator {
    display: none;
  }
  .react-select__menu {
    border: 1px solid #ebeff7;
    border-radius: 2px;
    margin-top: 5px;
    box-shadow: 0 4px 12px 0 rgba(4, 7, 13, 0.1);
  }
  .react-select__menu-list {
    padding: 0;
  }
  .react-select__option--is-focused {
    background-color: ${props => props.theme.colors.S100};
    &:active {
      background-color: ${props => props.theme.colors.S100};
    }
  }
  .react-select__option {
    cursor: pointer;
  }
`

const DropdownIndicator = (props) => {
  return (
    <components.DropdownIndicator {...props}>
      {props.isFocused
        ? <Icon name='Chevron-Up' />
        : <Icon name='Chevron-Down' />
      }
    </components.DropdownIndicator>
  )
}

const MultiSelect = ({
  options,
  values,
  placeholder,
  onChange,
  onInputChange
}) => {
  return (
    <SelectStyled
      isMulti
      onInputChange={onInputChange}
      closeMenuOnSelect={false}
      options={options}
      value={values}
      placeholder={placeholder}
      onChange={onChange}
      classNamePrefix='react-select'
      components={{ DropdownIndicator }}
    />
  )
}

DropdownIndicator.propTypes = {
  isFocused: PropTypes.bool
}

MultiSelect.propTypes = {
  options: PropTypes.arrayOf(PropTypes.object),
  values: PropTypes.oneOfType([PropTypes.array, PropTypes.object]),
  placeholder: PropTypes.string,
  onChange: PropTypes.func,
  onInputChange: PropTypes.func
}

export default MultiSelect
