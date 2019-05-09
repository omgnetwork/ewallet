import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import { Icon } from '../../omg-uikit'

const TagStyle = styled.div`
  display: inline-flex;
  flex-direction: row;
  align-items: center;
  padding: 5px 10px;
  background-color: ${props => props.theme.colors.S200};
  border-radius: 2px;
  font-weight: bold;
  font-size: ${props => props.small ? '12px' : 'inherit'};

  i {
    margin-right: 5px;
  }
`

const Tag = ({ title, icon, small }) => {
  return (
    <TagStyle small={small}>
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
  small: PropTypes.bool
}

export default Tag
