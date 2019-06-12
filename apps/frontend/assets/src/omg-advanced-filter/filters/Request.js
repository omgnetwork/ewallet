import React from 'react'
import PropTypes from 'prop-types'

import { Input } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const Request = ({ onRemove }) => {
  return (
    <FilterBox
      key='request'
      closeClick={onRemove}
    >
      <TagRow
        title='Request'
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

Request.propTypes = {
  onRemove: PropTypes.func.isRequired
}

export default Request
