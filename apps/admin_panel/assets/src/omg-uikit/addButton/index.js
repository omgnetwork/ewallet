import React, { Component } from 'react'
import styled from 'styled-components'
import Icon from '../icon'
const AddButtonCointainer = styled.button`
  border: 1px solid ${props => props.theme.colors.BL400};
  border-radius: 2px;
  display: inline-block;
  width: 30px;
  height: 30px;
  position: relative;
  text-align: center;
  cursor: pointer;
  transition: 0.2s;
  :hover {
    background-color: ${props => props.theme.colors.BL400};
  }
  :hover > i {
    color: white;
  }
  
  i {
    position: absolute;
    display: block;
    left: 0;
    right: 0;
    margin: 0 auto;
    top: 50%;
    transform: translateY(-50%);
    color:  ${props => props.theme.colors.BL400};
  }
`
class AddButton extends Component {
  render () {
    return (
      <AddButtonCointainer {...this.props}>
        <Icon name='Plus' />
      </AddButtonCointainer>
    )
  }
}

export default AddButton
