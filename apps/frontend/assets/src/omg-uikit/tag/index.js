import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import { Icon } from '../../omg-uikit'

const TagStyle = styled.div`
  display: inline-flex;
  flex-direction: row;
  align-items: center;
  align-self: flex-start;
  padding: 5px 10px;
  background-color: ${props => props.active ? props.theme.colors.S200 : 'none'};
  border-radius: 2px;
  font-weight: bold;
  font-size: ${props => props.small ? '12px' : 'inherit'};
  color: ${props => props.theme.colors.B400};
  transition: all 200ms ease-in-out;
  border: 1px solid transparent;

  :hover {
    border: 1px solid ${props => props.hoverStyle ? props.theme.colors.S300 : 'transparent'};
  }

  i {
    margin-right: 5px;
  }
`

const Tag = ({ title, icon, small, active = true, hoverStyle = false }) => {
  return (
    <TagStyle small={small} active={active} hoverStyle={hoverStyle}>
      {icon && (
        <Icon name={icon} />
      )}
      <span>
        {title}
      </span>
    </TagStyle>
  )
}

Tag.propTypes = {
  title: PropTypes.string.isRequired,
  icon: PropTypes.string,
  small: PropTypes.bool,
  active: PropTypes.bool,
  hoverStyle: PropTypes.bool
}

export default Tag
