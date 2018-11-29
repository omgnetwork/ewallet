import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Input, Select } from '../omg-uikit'
const ConfigRowContainer = styled.div`
  display: flex;
  border-bottom: ${props => (props.border ? `1px solid ${props.theme.colors.S200}` : 'none')};
`
const ConfigCol = styled.div`
  flex: 1 1 auto;
  padding: 20px;
  vertical-align: bottom;
  :first-child {
    flex: 0 1 220px;
    padding-left: 0;
    font-weight: 600;
  }
  :nth-child(2) {
    flex: 0 1 300px;
  }
  :last-child {
    padding-right: 0;
    flex: 0 1 300px;
  }
`

export default class ConfigRow extends Component {
  static propTypes = {
    description: PropTypes.string,
    value: PropTypes.string,
    options: PropTypes.array,
    name: PropTypes.string,
    type: PropTypes.string,
    onChange: PropTypes.func,
    onSelectItem: PropTypes.func,
    border: PropTypes.bool
  }

  static defaultProps = {
    type: 'input',
    options: []
  }

  render () {
    return (
      <ConfigRowContainer border={this.props.border}>
        <ConfigCol>{this.props.name}</ConfigCol>
        <ConfigCol>{this.props.description}</ConfigCol>
        <ConfigCol>
          {this.props.type === 'input' && <Input value={this.props.value} />}
          {this.props.type === 'select' && (
            <Select
              value={this.props.value}
              options={this.props.options}
              onChange={this.props.onChange}
              onSelectItem={this.props.onSelectItem}
            />
          )}
        </ConfigCol>
      </ConfigRowContainer>
    )
  }
}
