import React, { Component } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
const AvatarCircle = styled.div`
  width: ${props => (props.size ? `${props.size}px` : '30px')};
  height: ${props => (props.size ? `${props.size}px` : '30px')};
  background-color: ${props => props.theme.colors.S200};
  display: inline-block;
  background-image: url(${props => props.image});
  background-size: cover;
  vertical-align: middle;
  background-position: center;
  border-radius: 4px;
  font-weight: 600;
  text-align: center;
  font-size: 8px;
  position: relative;
  > div {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    margin: 0 auto;
    left: 0;
    right: 0;
    color: ${props => props.theme.colors.BL400};
  }
`
export default class Avatar extends Component {
  static propTypes = {
    image: PropTypes.string,
    name: PropTypes.string,
    size: PropTypes.number
  }
  static defaultProps = {
    name: ''
  }
  render () {
    const name = _.isNil(this.props.name)
      ? ''
      : String(this.props.name)
          .substring(0, 3)
          .toUpperCase()
    return (
      <AvatarCircle image={this.props.image} size={this.props.size} {...this.props}>
        <div>{this.props.image ? '' : name}</div>
      </AvatarCircle>
    )
  }
}
