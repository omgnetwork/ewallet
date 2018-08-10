import React, { Component } from 'react'
import styled, { keyframes } from 'styled-components'
import PropTypes from 'prop-types'
const progress = keyframes`
  0% {
    transform: translate3d(-250px, 0,0);
  }
  100% {
    transform: translate3d(100%, 0,0);
  }
`
const LoadingSkeletonSpan = styled.div`
  background-image: ${props =>
    `linear-gradient(90deg, ${props.theme.colors.S100},${props.theme.colors.S300},${
      props.theme.colors.S100
    })`};
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  top: 0;
  background-size: 250px 100%;
  background-repeat: no-repeat;
  border-radius: 10px;
  animation: ${progress} 1.5s ease-in-out infinite;
`
const LoadingBar = styled.div`
  position: relative;
  width: ${props => props.width || '100%'};
  height: ${props => props.height || '1.5em'};
  background-color: ${props => props.theme.colors.S100};
  overflow: hidden;
  border-radius: 10px;
`
class LoadingSkeleton extends Component {
  static propTypes = {
    height: PropTypes.string,
    width: PropTypes.string
  }
  render () {
    return (
      <LoadingBar {...this.props} height={this.props.height} width={this.props.width}>
        <LoadingSkeletonSpan />
      </LoadingBar>
    )
  }
}
export default LoadingSkeleton
