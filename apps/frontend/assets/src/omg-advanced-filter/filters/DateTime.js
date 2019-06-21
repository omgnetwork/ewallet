import React from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import moment from 'moment'

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
  const onDateChange = (key, date) => {
    if (date.format) {
      onUpdate({
        [config.key]: {
          ...values[config.key],
          [key]: date
        }
      })
    }
  }

  const onTimeChange = (key, time) => {
    if (time.format) {
      if (key === 'startTime') {
        const startDate = _.get(values[config.key], 'startDate', moment())
        onUpdate({
          [config.key]: {
            ...values[config.key],
            'startDate': startDate.set({
              hour: time.get('hour'),
              minute: time.get('minute')
            })
          }
        })
      }
      if (key === 'endTime') {
        const endDate = _.get(values[config.key], 'endDate', moment())
        onUpdate({
          [config.key]: {
            ...values[config.key],
            'endDate': endDate.set({
              hour: time.get('hour'),
              minute: time.get('minute')
            })
          }
        })
      }
    }
  }

  const startDate = _.get(values[config.key], 'startDate')
  const endDate = _.get(values[config.key], 'endDate')

  return (
    <FilterBox
      key={config.key}
      closeClick={onRemove}
    >
      <TagRow title={config.title} />
      <DateRowStyle>
        <DatePicker
          placeholder='From'
          onChange={date => onDateChange('startDate', date)}
          value={startDate ? moment(startDate) : ''}
        />
        <TimePicker
          hidePlaceholder
          onChange={time => onTimeChange('startTime', time)}
          value={startDate ? moment(startDate, 'hh:mm a') : ''}
        />
      </DateRowStyle>

      <DateRowStyle>
        <DatePicker
          placeholder='To'
          onChange={date => onDateChange('endDate', date)}
          value={endDate ? moment(endDate) : ''}
        />
        <TimePicker
          hidePlaceholder
          onChange={time => onTimeChange('endTime', time)}
          value={endDate ? moment(endDate, 'hh:mm a') : ''}
        />
      </DateRowStyle>
    </FilterBox>
  )
}

DateTime.propTypes = {
  onRemove: PropTypes.func.isRequired,
  onUpdate: PropTypes.func.isRequired,
  clearKey: PropTypes.func.isRequired,
  values: PropTypes.object,
  config: PropTypes.object
}

export default DateTime
