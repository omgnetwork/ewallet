import React from 'react'
import PropTypes from 'prop-types'

import { Input } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const TransferFrom = ({ onRemove }) => {
  return (
    <FilterBox
      key='transfer-from'
      closeClick={onRemove}
    >
      <TagRow
        title='From'
        tooltip='Test tooltip text'
      />

      <Input
        normalPlaceholder='Enter any ID or address'
        // onChange={this.onReEnteredNewPasswordInputChange}
        // value={this.state.reEnteredNewPassword}
      />
    </FilterBox>
  )
}

TransferFrom.propTypes = {
  onRemove: PropTypes.func.isRequired
}

export default TransferFrom
