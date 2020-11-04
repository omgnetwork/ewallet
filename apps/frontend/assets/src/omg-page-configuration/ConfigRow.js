import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input, Select, Checkbox } from '../omg-uikit'
const ConfigRowContainer = styled.div`
  display: flex;
  flex-direction: column;
  width: calc(50% - 60px);
  margin: 20px 60px 20px 0;
`
const ConfigCol = styled.div`
  vertical-align: bottom;
  :first-child {
    font-weight: 600;
    margin-bottom: 10px;
  }
  :last-child {
    margin-top: 10px;
  }
`
const RadioButtonsContainer = styled.div`
  display: flex;
  flex-direction: row;
  > div {
    display: inline-block;
    :first-child {
      margin-right: 15px;
    }
    :last-child {
      margin-top: 0;
    }
  }
`

class ConfigRow extends Component {
  static propTypes = {
    disabled: PropTypes.bool,
    description: PropTypes.string,
    value: PropTypes.any,
    options: PropTypes.array,
    name: PropTypes.string,
    type: PropTypes.string,
    onChange: PropTypes.func,
    onSelectItem: PropTypes.func,
    border: PropTypes.bool,
    placeholder: PropTypes.string,
    inputType: PropTypes.string,
    inputValidator: PropTypes.func,
    inputErrorMessage: PropTypes.string,
    valueRenderer: PropTypes.func,
    suffix: PropTypes.string
  }

  static defaultProps = {
    type: 'input',
    options: [],
    border: true,
    disabled: false
  }

  renderInputType () {
    return (
      <>
        {this.props.type === 'input' && (
          <Input
            disabled={this.props.disabled}
            suffix={this.props.suffix}
            value={this.props.value}
            normalPlaceholder={this.props.placeholder}
            onChange={this.props.onChange}
            type={this.props.inputType}
            validator={this.props.inputValidator}
            errorText={this.props.inputErrorMessage}
          />
        )}
        {this.props.type === 'select' && (
          <Select
            value={this.props.value}
            options={this.props.options}
            onChange={this.props.onChange}
            onSelectItem={this.props.onSelectItem}
            normalPlaceholder={this.props.placeholder}
            type={this.props.inputType}
            validator={this.props.inputValidator}
            errorText={this.props.inputErrorMessage}
          />
        )}
      </>
    )
  }

  render () {
    return (
      <ConfigRowContainer border={this.props.border}>
        <ConfigCol>{this.props.name}</ConfigCol>
        {this.props.type === 'boolean' && (
          <RadioButtonsContainer>
            <Checkbox checked={this.props.value} onClick={this.props.onChange} />
            <ConfigCol>{this.props.description}</ConfigCol>
          </RadioButtonsContainer>
        )}

        {this.props.type !== 'boolean' && (
          <>
            <ConfigCol>{this.props.description}</ConfigCol>
            <ConfigCol>
              {this.props.valueRenderer ? this.props.valueRenderer() : this.renderInputType()}
            </ConfigCol>
          </>
        )}
      </ConfigRowContainer>
    )
  }
}

export default ConfigRow
