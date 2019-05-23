import React from 'react'
import PropTypes from 'prop-types'

import { Select } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const WalletType = ({ onRemove }) => {
  return (
    <FilterBox
      key='wallet-type'
      closeClick={onRemove}
    >
      <TagRow
        title='Wallet Type'
        tooltip='Test tooltip text'
      />

      <Select
        normalPlaceholder='Select'
        // onSelectItem={this.onSelectExchangeAddressSelect}
        // value={this.state.exchangeAddress}
        // onChange={this.onChangeInputExchangeAddress}
        options={[
          { key: 'hot', value: 'Hot' },
          { key: 'local', value: 'Local' }
        ]}
      />
    </FilterBox>
  )
}

WalletType.propTypes = {
  onRemove: PropTypes.func.isRequired
}

export default WalletType
