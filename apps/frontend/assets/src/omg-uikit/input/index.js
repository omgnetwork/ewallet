import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import Icon from '../icon'
import { formatNumber, ensureIsNumberOnly } from '../../utils/formatter'

const Container = styled.div`
  position: relative;
  width: 100%;
`
const InnerContainer = styled.div`
  position: relative;
  display: flex;
  width: 100%;
`

const Placeholder = styled.span`
  position: absolute;
  pointer-events: none;
  left: 0;
  bottom: 0;
  padding-bottom: 10px;
  border-bottom: 1px solid transparent;
  color: ${props => props.theme.colors.B100};
  transition: 0.2s ease all;
  transform: ${props => (props.inputActive ? 'translate3d(0, -22px, 0)' : 'translate3d(0, 0, 0)')};
`

const Input = styled.input`
  flex: 1 1 0;
  width: 100%;
  border: none;
  color: ${props => props.theme.colors.B300};
  padding: 8px 0px;
  background-color: transparent;
  line-height: 1;
  border-bottom: 1px solid ${props => {
    if (props.error) {
      return props.theme.colors.R400
    }
    if (props.disabled || props.noBorder) {
      return 'transparent'
    }
    return props.theme.colors.S400
  }};
  :disabled {
    background-color: transparent;
    color: ${props => props.theme.colors.B300};
  }
  ::placeholder {
    color: ${props => props.theme.colors.S400};
    font-size: 12px;
  }
  :focus {
    border-bottom: 1px solid ${props => {
    if (props.error) {
      return props.theme.colors.R400
    }
    if (props.disabled || props.noBorder) {
      return 'transparent'
    }
    return props.theme.colors.BL400
  }};
  }

  ::-webkit-inner-spin-button,
  ::-webkit-outer-spin-button {
    -webkit-appearance: none;
    margin: 0;
  }

  :-webkit-autofill {
    content: 'AUTO_FILL_HACK';
    animation-name: onAutoFillStart;
    transition: background-color 50000s ease-in-out 0s;
  }
  @keyframes onAutoFillStart {
    from {
      /**/
    }
    to {
      /**/
    }
  }
`
const Error = styled.div`
  position: absolute;
  font-size: 12px;
  color: ${props => props.theme.colors.R400};
  text-align: left;
  padding-top: ${props => (props.error ? '2px' : 0)};
  overflow: hidden;
  max-height: ${props => (props.error ? '30px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity,
    0.3s ease padding ${props => (!props.error ? '0.3s' : '0s')};
`
const Success = styled.div`
  color: #50a895;
  text-align: left;
  padding-top: ${props => (props.success ? '5px' : 0)};
  overflow: hidden;
  max-height: ${props => (props.success ? '30px' : 0)};
  opacity: ${props => (props.success ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity,
    0.3s ease padding ${props => (!props.success ? '0.3s' : '0s')};
`
const Prefix = styled.div`
  display: flex;
  align-items: center;
  padding-right: 7px;
  border-bottom: 1px solid
    ${props =>
    props.error
      ? props.theme.colors.R400
      : props.active
        ? props.theme.colors.BL400
        : props.theme.colors.S400};
  i {
    color: ${props => props.theme.colors.BL400};
  }
`
const Suffix = styled.div`
  position: absolute;
  right: 0;
  bottom: 0;
  padding-right: 8px;
  padding-bottom: 8px;
  font-size: 12px;
  transition: 0.2s ease all;
  border-bottom: 1px solid transparent;
  color: ${props => props.theme.colors.B100};
`
class InputComponent extends PureComponent {
  static propTypes = {
    placeholder: PropTypes.string,
    normalPlaceholder: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    className: PropTypes.string,
    registerRef: PropTypes.func,
    error: PropTypes.oneOfType([PropTypes.string, PropTypes.bool]),
    errorText: PropTypes.node,
    success: PropTypes.bool,
    successText: PropTypes.number,
    autofocus: PropTypes.bool,
    onPressEnter: PropTypes.func,
    onPressEscape: PropTypes.func,
    onChange: PropTypes.func,
    prefix: PropTypes.node,
    suffix: PropTypes.node,
    onFocus: PropTypes.func,
    onBlur: PropTypes.func,
    value: PropTypes.oneOfType([PropTypes.string, PropTypes.number, PropTypes.any]),
    type: PropTypes.string,
    validator: PropTypes.func,
    allowNegative: PropTypes.bool,
    inputActive: PropTypes.bool,
    icon: PropTypes.string,
    noBorder: PropTypes.bool,
    maxAmountLength: PropTypes.number
  }
  static defaultProps = {
    onFocus: () => {},
    onBlur: () => {},
    onChange: () => {},
    registerRef: () => {},
    onPressEscape: () => {},
    onPressEnter: () => {},
    type: 'string',
    allowNegative: true
  }

  state = { active: false }

  componentDidMount = () => {
    if (this.props.autofocus) this.input.focus()
    this.props.registerRef(this.input)
    // HACK CHROME BUG AUTOFILL
    this.input.addEventListener('animationstart', e => {
      this.setState({ active: true })
    })
  }

  handleKeyPress = e => {
    if (e.key === 'Enter') {
      this.props.onPressEnter()
    }
  }
  handleKeyDown = e => {
    if (e.key === 'Escape') {
      this.props.onPressEscape()
    }
    if (!this.props.allowNegative && e.key === '-') {
      e.preventDefault()
    }
  }
  onFocus = e => {
    this.props.onFocus()
    this.setState({ active: true })
  }
  onBlur = e => {
    this.props.onBlur()
    this.setState({ active: false })
  }
  registerInput = input => (this.input = input)

  isInputActive = () => {
    return this.props.inputActive || this.props.value || this.state.active
  }
  onChange = e => {
    const value = e.target.value
    if (this.props.type === 'amount') {
      if (!ensureIsNumberOnly(value) && this.props.value.length < value.length) {
        return false
      }

      const length = ensureIsNumberOnly(value).length
      if (this.props.maxAmountLength && length >= this.props.maxAmountLength) {
        return false
      }
      const formattedAmount = formatNumber(value)

      const event = { ...e, target: { ...e.target, value: formattedAmount } }
      this.props.onChange(event)
    } else {
      this.props.onChange(e)
    }
  }
  render () {
    // eslint-disable-next-line no-unused-vars
    const {
      className,
      placeholder,
      onPressEscape,
      onPressEnter,
      autofocus,
      icon,
      ...rest
    } = this.props
    return (
      <Container className={className}>
        <InnerContainer>
          {icon && (
            <Prefix
              active={this.state.active}
              error={
                this.props.validator ? !this.props.validator(this.props.value) : this.props.error
              }
            >
              <Icon name={icon} />
            </Prefix>
          )}
          {this.props.prefix}
          <Input
            {...rest}
            value={this.props.type === 'amount' ? formatNumber(this.props.value) : this.props.value}
            onKeyPress={this.handleKeyPress}
            onKeyDown={this.handleKeyDown}
            ref={this.registerInput}
            placeholder={this.props.normalPlaceholder}
            onFocus={this.onFocus}
            onBlur={this.onBlur}
            onChange={this.onChange}
            error={
              this.props.validator ? !this.props.validator(this.props.value) : this.props.error
            }
            type={this.props.type === 'amount' ? 'string' : this.props.type}
          />
          <Placeholder inputActive={this.isInputActive()}>{placeholder}</Placeholder>
          <Suffix>{this.props.suffix}</Suffix>
        </InnerContainer>
        <Error
          error={this.props.validator ? !this.props.validator(this.props.value) : this.props.error}
        >
          {this.props.errorText}
        </Error>
        <Success success={this.props.success}>{this.props.successText}</Success>
      </Container>
    )
  }
}

export default InputComponent
