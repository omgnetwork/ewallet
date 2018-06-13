import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Input from '../input'
const SelectContainer = styled.div`
  position: relative;
`
const OptionsContainer = styled.div`
  position: absolute;
  z-index: 2;
  border: 1px solid #ebeff7;
  border-radius: 2px;
  box-shadow: 0 4px 12px 0 #e8eaed;
  background-color: white;
  right: 0;
  max-height: 200px;
  overflow: auto;
`
export default class Select extends Component {
  static propTypes = {
    value: PropTypes.string,
    onChange: PropTypes.func
  }

  render () {
    return (
      <SelectContainer>
        <Input onChange={this.props.onChange} value={this.props.value} />
        <OptionsContainer>
          <div>a</div>
          <div>b</div>
          <div>c</div>
        </OptionsContainer>
      </SelectContainer>
    )
  }
}
