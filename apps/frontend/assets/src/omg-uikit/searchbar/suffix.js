import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import Icon from '../icon'

const StyledIcon = styled(Icon)`
  font-size: 15px;
  width: 15px;
  height: 15px;
`

const Flipper = styled.div`
  cursor: pointer;
  width: 15px;
  height: 15px;

  .inner {
    position: relative;
    width: 100%;
    height: 100%;
    transition: transform 0.4s;
    transform-style: preserve-3d;
  }

  :hover .inner {
    transform: rotateY(180deg);
  }

  .front,
  .back {
    position: absolute;
    width: 100%;
    height: 100%;
    backface-visibility: hidden;
  }

  .front {
    background-color: white;
  }

  .back {
    background-color: white;
    transform: rotateY(180deg);
  }
`

const Suffix = ({ onClick }) => {
  return (
    <Flipper>
      <div className='inner'>
        <div className='front'>
          <StyledIcon name='Search' />
        </div>
        <div className='back'>
          <StyledIcon onClick={onClick} name='Close' />
        </div>
      </div>
    </Flipper>
  )
}

Suffix.propTypes = {
  onClick: PropTypes.func
}

export default Suffix
