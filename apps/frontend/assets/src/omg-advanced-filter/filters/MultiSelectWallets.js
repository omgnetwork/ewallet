import React, { useState } from 'react'
import PropTypes from 'prop-types'

import { createSearchAddressQuery } from '../../omg-wallet/searchField'
import AllWalletsFetcher from '../../omg-wallet/allWalletsFetcher'
import WalletSelect from '../../omg-wallet-select'
import { MultiSelect } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const MultiSelectWallets = ({
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
      <AllWalletsFetcher
        query={createSearchAddressQuery(search)}
        render={({ data }) => {
          return (
            <MultiSelect
              placeholder='Select wallet'
              onChange={onChange}
              onInputChange={onInputChange}
              values={values[config.key]}
              options={data.map(wallet => {
                return {
                  value: wallet.address,
                  label: <WalletSelect wallet={wallet} />
                }
              })}
            />
          )
        }}
      />
    </FilterBox>
  )
}

MultiSelectWallets.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.oneOfType([PropTypes.array, PropTypes.object]),
  config: PropTypes.object
}

export default MultiSelectWallets
