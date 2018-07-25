import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

const Container = styled.div`
  position: relative;
  width: 100%;
`
const InnerContainer = styled.div`
  position: relative;
  display: inline-block;
  width: 100%;
`

const Placeholder = styled.span`
  position: absolute;
  pointer-events: none;
  left: 0;
  bottom: 0;
  padding-bottom: 5px;
  font-size: 14px;
  transition: 0.2s ease all;
  border-bottom: 1px solid transparent;
  color: ${props => props.theme.colors.B100};
  transition: 0.2s;
  transform: ${props => (props.inputActive ? 'translate3d(0, -22px, 0)' : 'translate3d(0, 0, 0)')};
`

const Input = styled.input`
  width: 100%;
  border: none;
  color: ${props => props.theme.colors.B300};
  padding-bottom: 5px;
  background-color: transparent;
  line-height: 1;
  border-bottom: 1px solid
    ${props => (props.error ? props.theme.colors.R400 : props.theme.colors.S400)};
  :disabled {
    background-color: transparent;
    color: ${props => props.theme.colors.S400};
  }
  ::placeholder {
    color: ${props => props.theme.colors.S400};
  }
  :focus {
    border-bottom: 1px solid
      ${props => (props.error ? props.theme.colors.R400 : props.theme.colors.BL400)};
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
const Suffix = styled.div`
  position: absolute;
  right: 10px;
  bottom: 0;
  padding-bottom: 5px;
  transition: 0.2s ease all;
  border-bottom: 1px solid transparent;
  color: ${props => props.theme.colors.B100};
`
class InputComonent extends PureComponent {
  static propTypes = {
    placeholder: PropTypes.string,
    normalPlaceholder: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    className: PropTypes.string,
    registerRef: PropTypes.func,
    error: PropTypes.bool,
    errorText: PropTypes.node,
    success: PropTypes.bool,
    successText: PropTypes.number,
    autofocus: PropTypes.bool,
    onPressEnter: PropTypes.func,
    onPressEscape: PropTypes.func,
    onChange: PropTypes.func,
    suffix: PropTypes.node,
    onFocus: PropTypes.func,
    onBlur: PropTypes.func,
    value: PropTypes.string
  }
  static defaultProps = {
    onFocus: () => {},
    onBlur: () => {},
    onChange: () => {},
    registerRef: () => {},
    onPressEscape: () => {},
    onPressEnter: () => {}
  }
  state = {
    active: false
  }
  componentDidMount = () => {
    if (this.props.autofocus) this.input.focus()
    this.props.registerRef(this.input)
    if (this.input.value) {
      this.setState({ active: true })
    }
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
    return this.props.value || this.state.active
  }
  render () {
    const { className, placeholder, ...rest } = this.props
    return (
      <Container className={className}>
        <InnerContainer>
          <Input
            {...rest}
            onKeyPress={this.handleKeyPress}
            onKeyDown={this.handleKeyDown}
            innerRef={this.registerInput}
            placeholder={this.props.normalPlaceholder}
            onFocus={this.onFocus}
            onBlur={this.onBlur}
          />
          <Placeholder inputActive={this.isInputActive()}>{placeholder}</Placeholder>
          <Suffix>{this.props.suffix}</Suffix>
        </InnerContainer>
        <Error error={this.props.error}>{this.props.errorText}</Error>
        <Success success={this.props.success}>{this.props.successText}</Success>
      </Container>
    )
  }
}

export default InputComonent
