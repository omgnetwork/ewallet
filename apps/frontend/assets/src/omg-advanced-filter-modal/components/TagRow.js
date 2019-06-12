import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import { Tag } from '../../omg-uikit'

const TagRowStyle = styled.div`
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  margin-bottom: 5px;

  i {
    color: ${props => props.theme.colors.S400}
  }
`
const StyledTag = styled(Tag)`
  align-self: flex-start;
`

const TagRow = ({ title, tooltip }) => {
  return (
    <TagRowStyle>
      <StyledTag title={title} />
      {/* <Icon name='Info' /> */}
    </TagRowStyle>
  )
}

TagRow.propTypes = {
  title: PropTypes.string.isRequired,
  tooltip: PropTypes.string
}

export default TagRow
