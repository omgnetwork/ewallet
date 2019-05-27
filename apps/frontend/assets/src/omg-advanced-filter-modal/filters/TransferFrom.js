import React from 'react'
import PropTypes from 'prop-types'

import { Input } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const TransferFrom = ({
  onRemove,
  onUpdate,
  clearKey,
  values,
  config
}) => {
  const onChange = (e) => {
    e.target.value
      ? onUpdate({
        [config.code]: e.target.value
        // [config.code]: {
        //   value: e.target.value,
        //   config
        // }
      })
      : clearKey(config.code)
  }

  return (
    <FilterBox
      key={config.code}
      closeClick={onRemove}
    >
      <TagRow
        title='From'
        tooltip='Test tooltip text'
      />
      <Input
        normalPlaceholder='Enter any ID or address'
        onChange={onChange}
        value={values[config.code] || ''}
      />
    </FilterBox>
  )
}

TransferFrom.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.object,
  config: PropTypes.object
}

export default TransferFrom
