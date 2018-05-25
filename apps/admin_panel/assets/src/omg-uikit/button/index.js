import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import { ButtonPrimary } from './primary'
import { ButtonGhost } from './ghost'
import { ButtonSecondary } from './secondary'
import { Content } from './default'
import ReactLoading from 'react-loading'
import styled from 'styled-components'
const buttonMapStyle = {
  'primary': ButtonPrimary,
  'ghost': ButtonGhost,
  'secondary': ButtonSecondary
}
export default class Button extends PureComponent {
  static propTypes = {
    children: PropTypes.node,
    size: PropTypes.oneOf(['small', 'medium', 'large']),
    disabled: PropTypes.bool,
    className: PropTypes.string,
    loading: PropTypes.bool,
    onClick: PropTypes.func,
    fluid: PropTypes.bool,
    styleType: PropTypes.oneOf([ 'primary', 'secondary', 'ghost' ]),
    type: PropTypes.string
  }
  static defaultProps = {
    styleType: 'primary'
  }

  render () {
    const Button = buttonMapStyle[this.props.styleType]
    return (
      <Button
        onClick={this.props.onClick}
        size={this.props.size}
        disabled={this.props.disabled}
        className={this.props.className}
        loading={this.props.loading}
        fluid={this.props.fluid}
        styleType={this.props.styleType}
        type={this.props.type}
      >
        <ReactLoading className='loading' type='bars' color='white' height='30px' width='30px' />
        <Content loading={this.props.loading}>{this.props.children}</Content>
      </Button>
    )
  }
}

const PureButtonText = styled.button`
  border: none;
  color: ${props => props.theme.colors.BL400};
  background-color: transparent;
  cursor: pointer;
`
export class PlainButton extends PureComponent {
  static propTypes = {
    children: PropTypes.node
  }
  render () {
    return (
      <PureButtonText {...this.props}>{this.props.children}</PureButtonText>
    )
  }
}
