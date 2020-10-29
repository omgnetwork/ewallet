import React from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'

import Icon from '../icon'

const resolveType = type => {
  switch (type) {
    case 'info':
      return {
        icon: 'Info',
        background: '#fef7e5',
        iconColor: '#ffb200'
      }
    default: 
      return { }
  }
}

const BannerStyles = styled.div`
  background-color: ${props => resolveType(props.type).background};
  padding: 10px 24px;
  border-radius: 4px;
  display: flex;
  align-items: center;
`
const IconStyle = styled.div`
  border-radius: 100%;
  min-width: 20px;
  height: 20px;
  background-color: ${props => resolveType(props.type).iconColor};
  margin-right: 10px;
  text-align: center;
  i {
    color: white;
  }
`

const Banner = ({ type = 'info', text }) => {
  return (
    <BannerStyles type={type}>
      <IconStyle type={type}>
        <Icon name={resolveType(type).icon} />
      </IconStyle>
      {text}
    </BannerStyles>
  )
}

Banner.propTypes = {
  type: PropTypes.oneOf([ 'info' ]),
  text: PropTypes.string.isRequired
}

export default Banner
