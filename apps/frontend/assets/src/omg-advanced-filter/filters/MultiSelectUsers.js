import React, { useState } from 'react'
import PropTypes from 'prop-types'

import { createSearchUsersQuery } from '../../omg-users/searchField'
import UsersFetcher from '../../omg-users/usersFetcher'
import UserSelect from '../../omg-user-select'
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
  const [ search, setSearch ] = useState('')

  const onInputChange = e => {
    setSearch(e)
  }

  const onChange = (selection) => {
    const _selection = selection && selection.map(i => {
      return {
        key: i.value,
        value: i.value,
        label: i.value
      }
    })

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
        query={createSearchUsersQuery(search)}
        render={({ data }) => {
          return (
            <MultiSelect
              placeholder={config.placeholder}
              onChange={onChange}
              onInputChange={onInputChange}
              values={values[config.key]}
              options={data.map(user => {
                return {
                  value: user.username,
                  label: <UserSelect user={user} />
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
