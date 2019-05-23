import React from 'react'
import PropTypes from 'prop-types'

import { Input } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const SpecifyTarget = ({ onRemove }) => {
  return (
    <FilterBox
      key='specify-target'
      closeClick={onRemove}
    >
      <TagRow
        title='Specify Target'
        tooltip='Test tooltip text'
      />

      <Input
        normalPlaceholder='Enter any ID or address'
        // onChange={this.onReEnteredNewPasswordInputChange}
        // value={this.state.reEnteredNewPassword}
      />
    </FilterBox>
  )
}

SpecifyTarget.propTypes = {
  onRemove: PropTypes.func.isRequired
}

export default SpecifyTarget
