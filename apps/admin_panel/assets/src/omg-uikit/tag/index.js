import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import { Icon } from '../../omg-uikit'

const TagStyle = styled.div`
  display: inline-flex;
  flex-direction: row;
  align-items: center;
  padding: 8px 12px;
  background-color: ${props => props.theme.colors.S200};
  border-radius: 4px;
  font-weight: bold;

  .title {
    margin-left: 5px;
  }
`

const Tag = ({ title, icon }) => {
  return (
    <TagStyle>
      <Icon name={icon} />
      <span className='title'>
        {title}
      </span>
    </TagStyle>
  )
}

Tag.propTypes = {
  title: PropTypes.string.isRequired,
  icon: PropTypes.string.isRequired
}

export default Tag
