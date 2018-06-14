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
  width: 100%;
`
const OptionItem = styled.div`
  padding: 5px 10px;
  cursor: pointer;
  :hover {
    background-color: ${props => props.theme.colors.S100};
  }
`
export default class Select extends Component {
  static propTypes = {
    value: PropTypes.string,
    onChange: PropTypes.func
  }
  state = {
    active: false
  }
  registerRef = input => {
    this.input = input
  }
  onFocus = () => {
    this.setState({ active: true })
  }
  onBlur = e => {
    e.preventDefault()
    setTimeout(() => {
      this.setState({ active: false })
    })
  }
  onClickItem = item => e => {
    this.setState({ active: false, value: item })
  }
  render () {
    return (
      <SelectContainer>
        <Input
          {...this.props}
          onFocus={this.onFocus}
          onBlur={this.onBlur}
          onChange={this.props.onChange}
          value={this.state.value || this.props.value}
          registerRef={this.registerRef}
        />
        {this.state.active && (
          <OptionsContainer>
            <OptionItem onClick={this.onClickItem('OMG')}>OMG</OptionItem>
            <OptionItem onClick={this.onClickItem('BTC')}>BTC</OptionItem>
            <OptionItem onClick={this.onClickItem('ETH')}>ETH</OptionItem>
          </OptionsContainer>
        )}
      </SelectContainer>
    )
  }
}
