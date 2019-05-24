import React from 'react'
import PropTypes from 'prop-types'

import { Input } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const TransferFrom = ({ onRemove, onUpdate, clearKey, values }) => {
  const onChange = (e) => {
    if (e.target.value) {
      onUpdate({
        'transfer-from': e.target.value
      })
    } else {
      clearKey('transfer-from')
    }
  }
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
        onChange={onChange}
        value={values['transfer-from'] || ''}
      />
    </FilterBox>
  )
}

TransferFrom.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.object
}

export default TransferFrom
