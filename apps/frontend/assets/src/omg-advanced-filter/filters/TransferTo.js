import React from 'react'
import PropTypes from 'prop-types'

import AccountsFetcher from '../../omg-account/accountsFetcher'
import { createSearchMasterAccountQuery } from '../../omg-account/searchField'
import AccountSelect from '../../omg-account-select'
import { Select } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const TransferTo = ({
  onRemove,
  onUpdate,
  clearKey,
  values,
  config
}) => {
  const onChange = (e) => {
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
      <AccountsFetcher
        query={createSearchMasterAccountQuery(values[config.key])}
        render={({ data }) => {
          return (
            <Select
              value={values[config.key] || ''}
              onChange={onChange}
              onSelectItem={e => onUpdate({ [config.key]: e.id })}
              normalPlaceholder='Enter any ID or address'
              type='select'
              options={data.map(account => ({
                key: account.id,
                value: <AccountSelect account={account} />,
                ...account
              }))}
            />
          )
        }}
      />
    </FilterBox>
  )
}

TransferTo.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.object,
  config: PropTypes.object
}

export default TransferTo
