import React from 'react'
import PropTypes from 'prop-types'

import UsersFetcher from '../../omg-users/usersFetcher'
import { MultiSelect } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const MultiSelectUsers = ({
  onRemove,
  onUpdate,
  clearKey,
  values,
  config
}) => {
  const onChange = (selection) => {
    const _selection = selection && selection.map(i => i.value)
    _selection && _selection.length
      ? onUpdate({ [config.key]: _selection })
      : clearKey(config.key)
  }

  return (
    <FilterBox
      key={config.key}
      closeClick={onRemove}
    >
      <TagRow title={config.title} />
      <UsersFetcher
        render={({ data }) => {
          return (
            <MultiSelect
              placeholder={config.placeholder}
              onChange={onChange}
              value={values[config.key]}
              options={data.map(user => {
                return {
                  label: user.username || user.id,
                  value: user.id
                }
              })}
            />
          )
        }}
      />
    </FilterBox>
  )
}

MultiSelectUsers.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.oneOfType([PropTypes.array, PropTypes.object]),
  config: PropTypes.object
}

export default MultiSelectUsers
