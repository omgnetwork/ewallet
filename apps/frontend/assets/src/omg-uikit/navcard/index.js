import React from 'react'
import PropTypes from 'prop-types'
import { Link } from 'react-router-dom'
import styled from 'styled-components'

import Icon from '../icon'

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

const NavCard = ({ icon, title, subTitle, to, onClick, className }) => {
  const Resolved = to ? Link : 'div'
  return (
    <Resolved to={to} onClick={onClick}>
      <NavCardStyle className={className}>
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
    </Resolved>
  )
}

NavCard.propTypes = {
  icon: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  subTitle: PropTypes.string.isRequired,
  to: PropTypes.string,
  onClick: PropTypes.func,
  className: PropTypes.string
}

export default NavCard
