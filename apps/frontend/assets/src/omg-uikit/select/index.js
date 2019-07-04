import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Input from '../input'
import Icon from '../icon'
import { fuzzySearch } from '../../utils/search'
const SelectContainer = styled.div`
  position: relative;
  i[name='Chevron-Down'],
  i[name='Chevron-Up'] {
    cursor: pointer;
  }
`
const OptionsContainer = styled.div`
  position: absolute;
  bottom: -5px;
  transform: translateY(100%);
  z-index: 2;
  border: 1px solid #ebeff7;
  border-radius: 2px;
  box-shadow: 0 4px 12px 0 rgba(4, 7, 13, 0.1);
  background-color: white;
  left: 0;
  max-height: ${props => (props.optionBoxHeight ? props.optionBoxHeight : '150px')};
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
const ValueRendererContainer = styled.div`
  cursor: ${props => props.disabled ? 'initial' : 'pointer'};
  position: relative;
  display: flex;
  flex-direction: row;
  width: 100%;
  justify-content: space-between;
  align-items: center;
`
const ValueRendererSuffix = styled.div`
  padding-right: 8px;
  font-size: 12px;
  color: ${props => props.theme.colors.B100};
`

export default class Select extends PureComponent {
  static propTypes = {
    style: PropTypes.object,
    onSelectItem: PropTypes.func,
    options: PropTypes.array,
    value: PropTypes.string,
    valueRenderer: PropTypes.func,
    onChange: PropTypes.func,
    onFocus: PropTypes.func,
    onBlur: PropTypes.func,
    optionBoxHeight: PropTypes.string,
    className: PropTypes.string,
    filterByKey: PropTypes.bool,
    optionRenderer: PropTypes.func,
    disabled: PropTypes.bool,
    noBorder: PropTypes.bool,
    clearable: PropTypes.bool
  }
  static defaultProps = {
    onSelectItem: _.noop,
    onFocus: _.noop,
    onBlur: _.noop,
    filterByKey: false,
    value: '',
    clearable: false
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
      this.onBlur()
    })
  }
  onClickChevronDown = () => {
    this.onFocus()
    // HACK FOR FOCUSING SELECT WHEN CLOCK CHEVRON DOWN
    setTimeout(() => {
      this.input.focus()
    }, 0)
  }
  onClickClear = () => {
    this.onBlur()
    this.props.onSelectItem(null)
  }
  renderSuffix = () => {
    if (this.props.disabled) {
      return null
    }
    if (this.props.clearable && this.props.value) {
      return (
        <Icon
          name='Close'
          onMouseDown={this.onClickClear}
        />
      )
    }
    if (this.state.active) {
      return <Icon name='Chevron-Up' />
    }
    return (
      <Icon
        name='Chevron-Down'
        onMouseDown={this.onClickChevronDown}
      />
    )
  }
  render () {
    const filteredOption = this.props.filterByKey
      ? this.props.options.filter(option => {
        return fuzzySearch(this.props.value, option.key)
      })
      : this.props.options
    const {
      className,
      style,
      onSelectItem,
      disabled,
      value,
      valueRenderer,
      ...rest
    } = this.props

    return (
      <SelectContainer
        style={style}
        className={className}
        active={this.state.active}
      >
        {value && valueRenderer && (
          <ValueRendererContainer
            disabled={disabled}
            onClick={disabled ? null : this.onFocus}
            onBlur={this.onBlur}
            tabIndex='-1'
          >
            {valueRenderer(value)}
            <ValueRendererSuffix>
              {this.renderSuffix()}
            </ValueRendererSuffix>
          </ValueRendererContainer>
        )}
        {(!value || !valueRenderer) && (
          <Input
            {...rest}
            disabled={disabled}
            onFocus={this.onFocus}
            onBlur={this.onBlur}
            onChange={this.props.onChange}
            value={value}
            registerRef={this.registerRef}
            suffix={this.renderSuffix()}
          />
        )}
        {this.state.active && filteredOption.length > 0 && (
          <OptionsContainer optionBoxHeight={this.props.optionBoxHeight}>
            {filteredOption.map(option => {
              return (
                <OptionItem onMouseDown={this.onClickItem(option)} key={option.key}>
                  {this.props.optionRenderer ? this.props.optionRenderer(option.value) : option.value}
                </OptionItem>
              )
            })}
          </OptionsContainer>
        )}
      </SelectContainer>
    )
  }
}
