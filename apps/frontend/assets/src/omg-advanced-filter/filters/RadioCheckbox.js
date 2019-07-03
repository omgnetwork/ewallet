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
const Divider = styled.div`
  width: 100%;
  background-color: ${props => props.theme.colors.S100};
  height: 2px;
`

const RadioCheckbox = ({
  onRemove,
  onUpdate,
  clearKey,
  values,
  config
}) => {
  const toggle = (type) => {
    const currentValues = _.get(values, config.key, [])
    if (currentValues.includes(type)) {
      const newStatus = values[config.key].filter(i => i !== type)
      if (!newStatus.length) {
        clearKey(config.key)
      } else {
        onUpdate({ [config.key]: newStatus })
      }
    } else {
      onUpdate({ [config.key]: [type] })
    }
  }

  return (
    <FilterBox
      key={config.key}
      closeClick={onRemove}
    >
      <TagRow title={config.title} />
      <CheckboxGroup>
        {config.options.map((option, index) => {
          if (option === 'divider') {
            return <Divider key={index} />
          }
          return (
            <Checkbox
              key={index}
              label={option.label}
              onClick={() => toggle(option.value)}
              checked={values[config.key] && values[config.key].includes(option.value)}
            />
          )
        })}
      </CheckboxGroup>
    </FilterBox>
  )
}

RadioCheckbox.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  values: PropTypes.object,
  clearKey: PropTypes.func.isRequired,
  config: PropTypes.object
}

export default RadioCheckbox
