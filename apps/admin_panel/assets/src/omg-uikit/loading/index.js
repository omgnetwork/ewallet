import React, { Component } from 'react'
import styled, { keyframes } from 'styled-components'
import PropTypes from 'prop-types'
const progress = keyframes`
0% {
      background-position: -250px 0;
  }
  100% {
      background-position: calc(250px + 100%) 0;
  }
`
const LoadingSkeletonSpan = styled.div`
  background-color: ${props => props.theme.colors.S100};
  background-image: ${props =>
    `linear-gradient(90deg, ${props.theme.colors.S100},${props.theme.colors.S300},${
      props.theme.colors.S100
    })`};
  background-size: 250px 100%;
  background-repeat: no-repeat;
  border-radius: 10px;
  width: ${props => props.width || '100%'};
  height: ${props => props.height || '1.5em'};
  animation: ${progress} 1.5s ease-in-out infinite;
`
class LoadingSkeleton extends Component {
  static propTypes = {
    height: PropTypes.string,
    width: PropTypes.string
  }
  render () {
    return <LoadingSkeletonSpan {...this.props} height={this.props.height} width={this.props.width} />
  }
}
export default LoadingSkeleton
