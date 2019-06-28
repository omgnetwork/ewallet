import React, { useState } from 'react'
import PropTypes from 'prop-types'

import { createSearchUsersQuery } from '../../omg-users/searchField'
import UsersFetcher from '../../omg-users/usersFetcher'
import UserSelect from '../../omg-user-select'
import { Select } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const SelectUser = ({
  onRemove,
  onUpdate,
  clearKey,
  values,
  config
}) => {
  const [ searchValue, setSearchValue ] = useState(null)

  const onChange = (e) => {
    setSearchValue(e.target.value)
    e.target.value
      ? onUpdate({ [config.key]: e.target.value })
      : clearKey(config.key)
  }

  return (
    <FilterBox
      key={config.key}
      closeClick={onRemove}
    >
      <TagRow title={config.title} />
      <UsersFetcher
        query={createSearchUsersQuery(searchValue)}
        render={({ data }) => {
          return (
            <Select
              value={values[config.key]}
              onChange={onChange}
              onSelectItem={e => onUpdate({ [config.key]: e.username || e.email })}
              normalPlaceholder='Select user'
              type='select'
              options={data.map(user => {
                return {
                  key: user.username || user.email,
                  value: <UserSelect user={user} />,
                  ...user
                }
              })}
            />
          )
        }}
      />
    </FilterBox>
  )
}

SelectUser.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.object,
  config: PropTypes.object
}

export default SelectUser
