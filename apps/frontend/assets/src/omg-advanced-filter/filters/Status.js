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

const Status = ({
  onRemove,
  onUpdate,
  clearKey,
  values,
  config
}) => {
  const toggle = (type) => {
    if (_.get(values, config.key, []).includes(type)) {
      const newStatus = values[config.key].filter(i => i !== type)
      if (!newStatus.length) {
        clearKey(config.key)
      } else {
        onUpdate({ [config.key]: newStatus })
      }
    } else {
      const newStatus = values[config.key]
        ? [...values[config.key], type]
        : [type]
      onUpdate({ [config.key]: newStatus })
    }
  }

  return (
    <FilterBox
      key={config.key}
      closeClick={onRemove}
    >
      <TagRow title={config.title} />
      <CheckboxGroup>
        <Checkbox
          label='Confirmed'
          onClick={() => toggle('confirmed')}
          checked={values[config.key] && values[config.key].includes('confirmed')}
        />
        <Checkbox
          label='Pending'
          onClick={() => toggle('pending')}
          checked={values[config.key] && values[config.key].includes('pending')}
        />
        <Checkbox
          label='Failed'
          onClick={() => toggle('failed')}
          checked={values[config.key] && values[config.key].includes('failed')}
        />
      </CheckboxGroup>
    </FilterBox>
  )
}

Status.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  values: PropTypes.object,
  clearKey: PropTypes.func.isRequired,
  config: PropTypes.object
}

export default Status
