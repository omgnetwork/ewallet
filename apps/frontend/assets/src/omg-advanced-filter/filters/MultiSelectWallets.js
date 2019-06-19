import React from 'react'
import PropTypes from 'prop-types'

import WalletsFetcher from '../../omg-wallet/allWalletsFetcher'
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
  const onChange = (selection) => {
    selection
      ? onUpdate({ [config.key]: selection })
      : clearKey(config.key)
  }

  return (
    <FilterBox
      key={config.key}
      closeClick={onRemove}
    >
      <TagRow title={config.title} />
      <WalletsFetcher
        render={({ data }) => {
          return (
            <MultiSelect
              placeholder={config.placeholder}
              onChange={onChange}
              values={values[config.key]}
              options={data.map(wallet => {
                return {
                  label: wallet.address,
                  value: wallet.address
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
