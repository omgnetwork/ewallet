import React, { Component } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
const AvatarCircle = styled.div`
  width: 30px;
  height: 30px;
  background-color: #F0F2F5;
  display: inline-block;
  background-image: url(${props => props.image});
  background-size: cover;
  vertical-align: middle;
  background-position: center;
  color: ${props => props.theme.colors.BL400};
  font-weight: 600;
  text-align: center;
  line-height: 32px;
  font-size: 16px;
`
export default class Avatar extends Component {
  static propTypes = {
    image: PropTypes.string,
    name: PropTypes.string
  }
  static defaultProps = {
    name: ''
  }
  render () {
    return <AvatarCircle image={this.props.image} {...this.props}>{this.props.image ? '' : this.props.name.substring(0, 1).toUpperCase()}</AvatarCircle>
  }
}
