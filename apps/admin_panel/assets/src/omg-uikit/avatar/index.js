import React, { Component } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
const AvatarCircle = styled.div`
  border-radius: 50%;
  width: 30px;
  height: 30px;
  background-color: ${props => props.theme.colors.S400};
  display: inline-block;
  background-image: url(${props => props.image});
  background-size: cover;
  vertical-align: middle;
  background-position: center;
`
export default class Avatar extends Component {
  static propTypes = {
    image: PropTypes.string
  }
  render () {
    return <AvatarCircle image={this.props.image} {...this.props} />
  }
}
