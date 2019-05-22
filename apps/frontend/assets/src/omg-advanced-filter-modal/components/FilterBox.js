import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import { Icon } from '../../omg-uikit'

const FilterBoxStyle = styled.div`
  border: 1px solid ${props => props.theme.colors.S300};
  margin-bottom: 10px;
  border-radius: 4px;
  padding: 20px;
  position: relative;
  cursor: pointer;

  &:last-child {
    margin-bottom: 0;
  }

  &:hover {
    i[name="Close"] {
      opacity: 1;
    }
  }
`
const CloseStyle = styled(Icon)`
  color: ${props => props.theme.colors.S400};
  font-size: 0.6rem;
  position: absolute;
  top: 10px;
  right: 10px;
  opacity: 0;
  transition: all 200ms ease-in-out;
`

const FilterBox = ({ children, closeClick, ...props }) => {
  return (
    <FilterBoxStyle {...props}>
      <CloseStyle name='Close' onClick={closeClick} />
      {children}
    </FilterBoxStyle>
  )
}

FilterBox.propTypes = {
  children: PropTypes.node.isRequired,
  closeClick: PropTypes.func
}

export default FilterBox
