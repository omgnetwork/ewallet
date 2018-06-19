import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Input from '../input'
import Icon from '../icon'
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
  max-height: 150px;
  overflow: auto;
  width: 100%;
`
const OptionItem = styled.div`
  padding: 10px 10px;
  cursor: pointer;
  :hover {
    background-color: ${props => props.theme.colors.S100};
  }
`
export default class Select extends Component {
  static propTypes = {
    onSelect: PropTypes.func,
    options: PropTypes.array
  }
  state = {
    active: false,
    value: ''
  }
  registerRef = input => {
    this.input = input
  }
  onFocus = () => {
    this.setState({ active: true, value: '' })
  }
  onBlur = e => {
    this.setState({ active: false })
  }
  onClickItem = item => e => {
    this.setState({ active: false, value: item.value }, () => {
      this.props.onSelect && this.props.onSelect(item)
    })
  }
  onChange = e => {
    this.setState({ value: e.target.value })
  }
  render () {
    return (
      <SelectContainer>
        <Input
          {...this.props}
          onFocus={this.onFocus}
          onBlur={this.onBlur}
          onChange={this.onChange}
          value={this.state.value}
          registerRef={this.registerRef}
          suffix={this.state.active ? <Icon name='Chevron-Up' /> : <Icon name='Chevron-Down' />}
        />
        {this.state.active && (
          <OptionsContainer>
            {this.props.options
              .filter(option => new RegExp(this.state.value).test(option.value))
              .map(option => {
                return (
                  <OptionItem onMouseDown={this.onClickItem(option)} key={option.key}>
                    {option.value}
                  </OptionItem>
                )
              })}
          </OptionsContainer>
        )}
      </SelectContainer>
    )
  }
}
