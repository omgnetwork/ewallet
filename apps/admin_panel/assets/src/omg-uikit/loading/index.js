import React, { Component } from 'react'
import styled, { keyframes } from 'styled-components'
import PropTypes from 'prop-types'
const progress = keyframes`
0% {
      background-position: -200px 0;
  }
  100% {
      background-position: calc(200px + 100%) 0;
  }
`
const LoadingSkeletonSpan = styled.div`
  background-color: #eee;
  background-image: linear-gradient(90deg, #eee, #f5f5f5, #eee);
  background-size: 200px 100%;
  background-repeat: no-repeat;
  border-radius: 4px;
  width: 100%;
  height: ${props => props.height || '1.5em'};
  animation: ${progress} 1.5s ease-in-out infinite;
  opacity: 0.5;
`
class LoadingSkeleton extends Component {
  static propTypes = {
    height: PropTypes.string
  }
  render () {
    return <LoadingSkeletonSpan height={this.props.height} />
  }
}
export default LoadingSkeleton
