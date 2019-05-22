import React from 'react'
import PropTypes from 'prop-types'

import FilterBox from '../components/FilterBox'

const TransferTo = ({ onRemove }) => {
  return (
    <FilterBox
      key='transfer-to'
      closeClick={onRemove}
    >
      Transfer To
    </FilterBox>
  )
}

TransferTo.propTypes = {
  onRemove: PropTypes.func.isRequired
}

export default TransferTo
