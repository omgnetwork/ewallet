import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
const IconComponent = styled.i`
  vertical-align: middle;
  padding: ${props => (props.button ? '8px' : '0')};
  border-radius: ${props => (props.button ? '2px' : '0')};
  cursor: ${props => (props.button ? 'pointer' : 'inherit')};
  display: inline-block;
  width: 1em;
  height: 1em;

  :hover {
    background-color: ${props =>
      props.button && props.hoverable ? props.theme.colors.S200 : 'transparent'};
  }
`
export default class Icon extends Component {
  static propTypes = {
    name: PropTypes.string,
    button: PropTypes.bool,
    onClick: PropTypes.func,
    hoverable: PropTypes.bool
  }
  static defaultProps = {
    hoverable: true
  }
  render () {
    return (
      <IconComponent
        className={`icon-omisego_${this.props.name}`}
        hoverable={this.props.hoverable}
        button={this.props.button}
        onClick={this.props.onClick}
      />
    )
  }
}
