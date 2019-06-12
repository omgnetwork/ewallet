import React from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'

import { DatePicker, TimePicker } from '../../omg-uikit'
import FilterBox from '../components/FilterBox'
import TagRow from '../components/TagRow'

const DateRowStyle = styled.div`
  display: flex;
  flex-direction: row;
  > div {
    &:first-child {
      margin-right: 20px;
    }
  }
`
const DateTime = ({
  onRemove,
  onUpdate,
  clearKey,
  values,
  config
}) => {
  return (
    <FilterBox
      key={config.key}
      closeClick={onRemove}
    >
      <TagRow title={config.title} />
      <DateRowStyle>
        <DatePicker placeholder='Start' />
        <TimePicker hidePlaceholder />
      </DateRowStyle>

      <DateRowStyle>
        <DatePicker placeholder='End' />
        <TimePicker hidePlaceholder />
      </DateRowStyle>
    </FilterBox>
  )
}

DateTime.propTypes = {
  onRemove: PropTypes.func.isRequired
}

export default DateTime
