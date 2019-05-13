import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

const SwitchContainer = styled.div`
  width: 45px;
  height: 22px;
  border-radius: 50px;
  position: relative;
  background-color: ${props => props.open ? '#65D2BB' : '#ECECEC'};
  cursor: pointer;
`
const Slide = styled.div`
  height: 17px;
  width: 17px;
  position: absolute;
  left: 2px;
  top: 50%;
  transform: ${props => props.open ? 'translate3d(22px,-50%,0)' : 'translate3d(0,-50%,0)'};
  transition: 0.3s;
  border-radius: 50%;
  background-color: white;
`
export default class Switch extends Component {
  static propTypes = {
    open: PropTypes.bool
  }

  render () {
    return (
      <SwitchContainer open={this.props.open} {...this.props}>
        <Slide open={this.props.open} />
      </SwitchContainer>
    )
  }
}
