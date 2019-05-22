import React from 'react'
import PropTypes from 'prop-types'

import FilterBox from '../components/FilterBox'

const TransferFrom = ({ onRemove }) => {
  return (
    <FilterBox
      key='transfer-from'
      closeClick={onRemove}
    >
      Transfer From
    </FilterBox>
  )
}

TransferFrom.propTypes = {
  onRemove: PropTypes.func.isRequired
}

export default TransferFrom
