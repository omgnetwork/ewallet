import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
const RadioButtonContainer = styled.div`
    width: 16px;
    height: 16px;
    position: relative;
    border: 1px solid ${props => props.checked ? props.theme.colors.BL400 : props.theme.colors.S400};
    display: inline-block;
    cursor: pointer;
    vertical-align: middle;
    border-radius: 50%;
`
const Container = styled.div`
  position: relative;
`
const Checked = styled.div`
    transition: 0.2s;
    transform: translateY(-50%) ${props => props.checked ? 'scale3d(1,1,1)' : 'scale3d(0,0,0)'};
    width: 8px;
    height: 8px;
    position: absolute;
    border-radius: 50%;
    top: 50%;
    left: 0;
    right: 0;
    margin: 0 auto;
    
    background-color: ${props => props.theme.colors.BL400};
`
const Label = styled.label`
  margin-left: 5px;
  vertical-align: middle;
`
class RadioButton extends Component {
  static propTypes = {
    checked: PropTypes.bool,
    onClick: PropTypes.func,
    label: PropTypes.string
  }

  render () {
    return (
      <Container onClick={this.props.onClick} {...this.props}>
        <RadioButtonContainer checked={this.props.checked}>
          <Checked checked={this.props.checked} />
        </RadioButtonContainer>
        <Label>{this.props.label}</Label>
      </Container>
    )
  }
}
export default RadioButton
