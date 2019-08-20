import React, { useState } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'

import Select from '../select'
import Input from '../input'

const Wrapper = styled.div`
  display: flex;
  flex-direction: column;
`
const Labels = styled.div`
  display: flex;
  flex-direction: row;
  margin: 7px 0;
  color: ${props => props.theme.colors.B100};
  font-size: 12px;
  div:first-child {
    flex: 1 1 0;
  }
  div:last-child {
    flex: 2 1 0;
    margin-left: 15px;
  }
`
const SelectInputContainer = styled.div`
  input {
    margin: 0 !important;
    display: flex;
    align-items: center;
  }
  display: flex;
  flex-direction: row;
  border-radius: 6px;
  transition: all 150ms ease-in-out;
  border: 1px solid ${props => {
    if (props.focused) {
      return props.theme.colors.BL400
    }
    if (props.error) {
      return props.theme.colors.R400
    }
    if (props.disabled || props.noBorder) {
      return 'transparent'
    }
    return props.theme.colors.S400
  }};
`
const StyledSelect = styled(Select)`
  flex: 1 1 0;
  height: 60px;
  display: flex;
  align-items: center;
  width: 100%;
  padding: 0 10px;
`
const StyledInput = styled(Input)`
  flex: 2 1 0;
  padding: 0 10px;
  border-left: 1px solid ${props => props.theme.colors.S400};
`
const EmptyAvatar = styled.div`
  width: 30px;
  height: 30px;
  border-radius: 4px;
  margin-right: 10px;
  margin-top: 2px;
  border: 1px solid ${props => props.theme.colors.S300};
`

const SelectInput = ({ inputProps = {}, selectProps = {}, className }) => {
  const [ focused, setFocused ] = useState(false)

  const { label: inputLabel, ...restInput } = inputProps
  const { label: selectLabel, ...restSelect } = selectProps

  return (
    <Wrapper className={className}>
      <Labels>
        <div>{selectLabel}</div>
        <div>{inputLabel}</div>
      </Labels>
      <SelectInputContainer focused={focused}>
        {!_.isEmpty(selectProps) && (
          <StyledSelect
            noBorder
            onFocus={() => setFocused(true)}
            onBlur={() => setFocused(false)}
            prefix={<EmptyAvatar />}
            {...restSelect}
          />
        )}
        {!_.isEmpty(inputProps) && (
          <StyledInput
            noBorder
            placeholder={inputProps.placeholder}
            onFocus={() => setFocused(true)}
            onBlur={() => setFocused(false)}
            {...restInput}
          />
        )}
      </SelectInputContainer>
    </Wrapper>
  )
}

SelectInput.propTypes = {
  inputProps: PropTypes.object,
  selectProps: PropTypes.object,
  className: PropTypes.string
}

export default SelectInput
