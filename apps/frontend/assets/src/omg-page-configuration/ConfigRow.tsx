import React, { Component } from 'react'
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


interface ConfigRowProps {
  border?: boolean
  description: string
  disabled?: boolean
  inputErrorMessage?: string
  inputType?: string
  inputValidator?: (...args: any) => boolean
  name: string
  onChange?: Function
  onSelectItem?: Function
  options?: []
  placeholder?: string
  suffix?: string
  type?: 'boolean' | 'input' | 'select'
  value: any
  valueRenderer?: Function
}

class ConfigRow extends Component<ConfigRowProps> {
  static defaultProps = {
    type: 'input',
    options: [],
    border: true,
    disabled: false
  }

  renderInputType (): JSX.Element {
    switch (this.props.type) {
      case 'input':
        return (
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
        )

      case 'select':
        return (
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
        )
      default:
        return null
    }
  }

  render () {
    return (
      <ConfigRowContainer>
        <ConfigCol>{this.props.name}</ConfigCol>
        {this.props.type === 'boolean' ? (
          <RadioButtonsContainer>
            <Checkbox
              checked={this.props.value}
              onClick={this.props.onChange}
            />
            <ConfigCol>{this.props.description}</ConfigCol>
          </RadioButtonsContainer>
        ) : (
          <>
            <ConfigCol>{this.props.description}</ConfigCol>
            <ConfigCol>
              {this.props.valueRenderer
                ? this.props.valueRenderer()
                : this.renderInputType()}
            </ConfigCol>
          </>
        )}
      </ConfigRowContainer>
    )
  }
}

export default ConfigRow
