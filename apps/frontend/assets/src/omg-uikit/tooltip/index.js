import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

const TooltipStyle = styled.div`
  position: relative;
  display: inline-block;

  & .triangle {
    opacity: 0;
    background-color: ${props => props.theme.colors.B400};
    pointer-events: none;
    width: 10px;
    height: 10px;
    transform: rotate(45deg);

    top: -14px;
    right: 7px;

    position: absolute;
    z-index: 1;
  }

  & .tooltip-text {
    opacity: 0;
    background-color: ${props => props.theme.colors.B400};
    color: white;
    text-align: center;
    padding: 5px 10px;
    border-radius: 2px;
    pointer-events: none;
    top: -35px;
    right: 0;

    display: flex;
    flex: 1 1 0;
    position: absolute;
    z-index: 1;
  }

  &:hover .tooltip-text {
    opacity: 1;
  }
  &:hover .triangle {
    opacity: 1;
  }
`

const Tooltip = ({ text, children }) => {
  return (
    <TooltipStyle>
      {children}
      <span className='tooltip-text'>{text}</span>
      <span className='triangle' />
    </TooltipStyle>
  )
}

Tooltip.propTypes = {
  text: PropTypes.string.isRequired,
  children: PropTypes.node.isRequired
}

export default Tooltip
