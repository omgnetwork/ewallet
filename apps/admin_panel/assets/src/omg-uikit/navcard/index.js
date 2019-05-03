import React from 'react'
import PropTypes from 'prop-types'
import { Link } from 'react-router-dom'
import styled from 'styled-components'

import { Icon } from '..'

const NavCardStyle = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
  color: ${props => props.theme.colors.B300};
  border: 1px solid ${props => props.theme.colors.S400};
  padding: 30px;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;

  .icon {
    font-weight: bold;
    margin-right: 30px;
  }

  .text {
    display: flex;
    flex-direction: column;

    .title {
      font-weight: bold;
    }
    .subtitle {
      font-size: 10px;
      color: ${props => props.theme.colors.B100};
    }
  }
`

const NavCard = ({ icon, title, subTitle, to, className, style }) => {
  return (
    <div className={className} style={style}>
      <Link to={to}>
        <NavCardStyle>
          <Icon name={icon} className='icon' />
          <div className='text'>
            <div className='title'>
              {title}
            </div>
            <div className='subtitle'>
              {subTitle}
            </div>
          </div>
        </NavCardStyle>
      </Link>
    </div>
  )
}

NavCard.propTypes = {
  icon: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  subTitle: PropTypes.string.isRequired,
  to: PropTypes.string.isRequired,
  style: PropTypes.object,
  className: PropTypes.string
}

export default NavCard
