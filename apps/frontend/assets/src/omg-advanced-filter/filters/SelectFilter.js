import React from 'react'
import PropTypes from 'prop-types'

import { Select } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const SelectFilter = ({
  onRemove,
  onUpdate,
  clearKey,
  values,
  config
}) => {
  return (
    <FilterBox
      key={config.key}
      closeClick={onRemove}
    >
      <TagRow title={config.title} />
      <Select
        normalPlaceholder='Select'
        onSelectItem={e => onUpdate({ [config.key]: e.key })}
        value={_.capitalize(values[config.key]) || ''}
        options={config.options}
      />
    </FilterBox>
  )
}

SelectFilter.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.object,
  config: PropTypes.object
}

export default SelectFilter
