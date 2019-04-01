import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
const CheckboxContainer = styled.div`
  width: 16px;
  height: 16px;
  position: relative;
  border: 1px solid ${props => (props.checked ? props.theme.colors.BL400 : props.theme.colors.S500)};
  border-radius: 2px;
  display: inline-block;
  vertical-align: middle;
  cursor: pointer;
  transition: 0.2s;
  background-color: 'white';
`
const Container = styled.div`
  position: relative;
`
const Checked = styled.div`
  transition: 0.2s;
  transform: translateY(-50%);
  position: absolute;
  top: 50%;
  left: 0;
  right: 0;
  margin: 0 auto;
  text-align: center;
  color: ${props => (props.checked ? props.theme.colors.BL400 : 'white')};
  font-size: 0.7em;
`
const Label = styled.label`
  margin-left: 10px;
  vertical-align: middle;
`
export default class Checkbox extends Component {
  static propTypes = {
    checked: PropTypes.bool,
    onClick: PropTypes.func,
    label: PropTypes.string
  }

  render () {
    return (
      <Container>
        <CheckboxContainer onClick={this.props.onClick} {...this.props}>
          <Checked checked={this.props.checked}>✓</Checked>
        </CheckboxContainer>
        <Label>{this.props.label}</Label>
      </Container>
    )
  }
}
