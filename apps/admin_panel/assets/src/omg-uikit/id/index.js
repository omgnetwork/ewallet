import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import Copy from '../../omg-copy'

const IdStyle = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;

  .data {
    white-space: nowrap;
    margin-right: 10px;
    overflow-x: ellipsis;
    max-width: ${props => `${props.maxWidth}px`};
  }
`
const Id = ({ maxWidth = 200, withCopy = true, children }) => {
  return (
    <IdStyle maxWidth={maxWidth}>
      <div className='data'>{children}</div>
      {withCopy && <Copy data={children} />}
    </IdStyle>
  )
}

Id.propTypes = {
  maxWidth: PropTypes.number,
  withCopy: PropTypes.bool,
  children: PropTypes.node.isRequired
}

export default Id
