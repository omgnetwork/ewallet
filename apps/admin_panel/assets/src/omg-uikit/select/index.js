import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Input from '../input'
import Icon from '../icon'
import { fuzzySearch } from '../../utils/search'
const SelectContainer = styled.div`
  position: relative;
`
const OptionsContainer = styled.div`
  position: absolute;
  z-index: 2;
  border: 1px solid #ebeff7;
  border-radius: 2px;
  box-shadow: 0 4px 12px 0 rgba(4, 7, 13, 0.1);
  background-color: white;
  right: 0;
  max-height: ${props => props.optionBoxHeight ? props.optionBoxHeight : '150px'};
  overflow: auto;
  min-width: 100%;
`
const OptionItem = styled.div`
  padding: 10px 10px;
  cursor: pointer;
  :hover {
    background-color: ${props => props.theme.colors.S100};
  }
`
export default class Select extends PureComponent {
  static propTypes = {
    onSelectItem: PropTypes.func,
    options: PropTypes.array,
    value: PropTypes.string,
    onChange: PropTypes.func,
    onFocus: PropTypes.func,
    onBlur: PropTypes.func,
    optionBoxHeight: PropTypes.string
  }
  static defaultProps = {
    onSelectItem: _.noop,
    onFocus: _.noop,
    onBlur: _.noop
  }
  state = {
    active: false
  }

  registerRef = input => {
    this.input = input
  }
  onFocus = () => {
    this.setState({ active: true })
    this.props.onFocus()
  }
  onBlur = e => {
    this.props.onBlur()
    this.setState({ active: false })
  }
  onClickItem = item => e => {
    this.setState({ active: false }, () => {
      this.props.onSelectItem(item)
    })
  }
  render () {
    const filteredOption = this.props.options.filter(option => {
      return fuzzySearch(this.props.value, option.key)
    })
    return (
      <SelectContainer>
        <Input
          {...this.props}
          onFocus={this.onFocus}
          onBlur={this.onBlur}
          onChange={this.props.onChange}
          value={this.props.value}
          registerRef={this.registerRef}
          suffix={this.state.active ? <Icon name='Chevron-Up' /> : <Icon name='Chevron-Down' />}
        />
        {this.state.active &&
          filteredOption.length > 0 && (
            <OptionsContainer optionBoxHeight={this.props.optionBoxHeight}>
              {filteredOption.map(option => {
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
