import React, { useState } from 'react'
import PropTypes from 'prop-types'

import { createSearchAddressQuery } from '../../omg-wallet/searchField'
import AllWalletsFetcher from '../../omg-wallet/allWalletsFetcher'
import WalletSelect from '../../omg-wallet-select'
import { Select } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const SelectWallet = ({
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
      <AllWalletsFetcher
        query={createSearchAddressQuery(searchValue)}
        render={({ data }) => {
          return (
            <Select
              value={values[config.key] || ''}
              onChange={onChange}
              onSelectItem={e => onUpdate({ [config.key]: e.key })}
              normalPlaceholder='Select wallet'
              type='select'
              options={data
                .filter(w => w.identifier !== 'burn')
                .map(d => ({
                  key: d.address,
                  value: <WalletSelect wallet={d} />,
                  ...d
                }))}
            />
          )
        }}
      />
    </FilterBox>
  )
}

SelectWallet.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.object,
  config: PropTypes.object
}

export default SelectWallet
