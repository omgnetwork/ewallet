import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import Icon from '../icon'

const DetailRowStyle = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
  width: 100%;
  position: relative;

  .icon {
    margin-right: 20px;
    color: ${props => props.theme.colors.B100}
  }
`
const RowStyle = styled.div`
  display: flex;
  flex-direction: row;
  border-bottom: 1px solid ${props => props.theme.colors.S200};
  padding: 15px 0;
  flex: 1 1 0;
  justify-content: space-between;
  align-items: center;

  .label {
    color: ${props => props.theme.colors.B100};
  }

  .value {
    display: flex;
    flex-direction: row;
    align-items: center;
    position: absolute;
    right: 0;
  }
`

const DetailRow = ({
  icon = 'Option-Horizontal',
  label,
  value
}) => {
  return (
    <DetailRowStyle>
      <Icon className='icon' name={icon} />
      <RowStyle>
        <span className='label'>{label}</span>
        <span className='value'>{value}</span>
      </RowStyle>
    </DetailRowStyle>
  )
}

DetailRow.propTypes = {
  icon: PropTypes.string,
  label: PropTypes.string.isRequired,
  value: PropTypes.node.isRequired
}

export default DetailRow
