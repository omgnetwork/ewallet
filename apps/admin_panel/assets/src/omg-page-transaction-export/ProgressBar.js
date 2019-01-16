import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

const ProgressBarContainer = styled.div`
  height: 10px;
  border-radius: 20px;
  background-color: ${props => props.theme.colors.S400};
  position: relative;
`
const Progress = styled.div`
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  border-top-left-radius: 20px;
  border-bottom-left-radius: 20px;
  bottom: 0;
  width: ${props => props.percentage}%;
  background-color: ${props => props.theme.colors.BL400};
`
export default class ProgressBar extends Component {
  static propTypes = {
    percentage: PropTypes.number
  }

  render () {
    return (
      <ProgressBarContainer>
        <Progress percentage={this.props.percentage} />
      </ProgressBarContainer>
    )
  }
}
