import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import Copy from '../../omg-copy'

const IdStyle = styled.div`
  display: inline-flex;
  flex-direction: row;
  align-items: center;

  .data {
    white-space: nowrap;
    margin-right: ${props => props.withCopy ? '10px' : '0px'};
    overflow-x: hidden;
    text-overflow: ellipsis;
    max-width: ${props => props.maxChar ? 'none' : `${props.maxWidth}px`};
  }
`
const Id = ({ maxWidth = 200, withCopy = true, maxChar, children }) => {
  return (
    <IdStyle maxWidth={maxWidth} maxChar={maxChar} withCopy={withCopy}>
      <div className='data'>
        {maxChar
          ? _.truncate(children, { 'length': maxChar })
          : children}
      </div>
      {withCopy && <Copy data={children} />}
    </IdStyle>
  )
}

Id.propTypes = {
  maxWidth: PropTypes.number,
  maxChar: PropTypes.number,
  withCopy: PropTypes.bool,
  children: PropTypes.node.isRequired
}

export default Id
