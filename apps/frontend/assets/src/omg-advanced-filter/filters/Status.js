import React from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'

import { Checkbox } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const CheckboxGroup = styled.div`
  display: flex;
  flex-direction: column;
  margin-top: 10px;
  > div {
    margin-bottom: 10px;
    &:last-child {
      margin-bottom: 0;
    }
  }
`

const Status = ({ onRemove, onUpdate, values, clearKey }) => {
  const toggle = (type) => {
    if (_.get(values, `status.${type}`)) {
      const newStatus = _.omit(values['status'], [type])
      if (!_.isEmpty(newStatus)) {
        onUpdate({ 'status': newStatus })
      } else {
        clearKey('status')
      }
    } else {
      // add type true
      const newStatus = {
        ...values['status'],
        [type]: true
      }
      onUpdate({ 'status': { ...newStatus } })
    }
  }

  return (
    <FilterBox
      key='status'
      closeClick={onRemove}
    >
      <TagRow
        title='Status'
        tooltip='Test tooltip text'
      />
      <CheckboxGroup>
        <Checkbox
          label='Success'
          onClick={() => toggle('success')}
          checked={_.get(values, 'status.success', false)}
        />
        <Checkbox
          label='Pending'
          onClick={() => toggle('pending')}
          checked={_.get(values, 'status.pending', false)}
        />
        <Checkbox
          label='Failed'
          onClick={() => toggle('failed')}
          checked={_.get(values, 'status.failed', false)}
        />
      </CheckboxGroup>
    </FilterBox>
  )
}

Status.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  values: PropTypes.object,
  clearKey: PropTypes.func.isRequired
}

export default Status
