import React, { useState } from 'react'
import PropTypes from 'prop-types'

import TokensFetcher from '../../omg-token/tokensFetcher'
import { createSearchTokenQuery } from '../../omg-token/searchField'
import TokenSelect from '../../omg-token-select'
import { Select } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const SelectToken = ({
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
      <TokensFetcher
        query={createSearchTokenQuery(searchValue)}
        render={({ data }) => {
          return (
            <Select
              value={values[config.key]}
              onChange={onChange}
              onSelectItem={e => onUpdate({ [config.key]: e.symbol })}
              normalPlaceholder='Select token'
              type='select'
              options={data.map(token => {
                return {
                  key: token.symbol,
                  value: <TokenSelect token={token} />,
                  ...token
                }
              })}
            />
          )
        }}
      />
    </FilterBox>
  )
}

SelectToken.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.object,
  config: PropTypes.object
}

export default SelectToken
