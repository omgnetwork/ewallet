import React, { PureComponent } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import DateTime from 'react-datetime'

import Input from '../input'

const StyledDateTime = styled(DateTime)`
  flex: 1 0 0;
  margin-top: 30px;
`

class TimePicker extends PureComponent {
  static propTypes = {
    onChange: PropTypes.func,
    value: PropTypes.oneOfType([PropTypes.object, PropTypes.string]),
    onFocus: PropTypes.func,
    placeholder: PropTypes.string,
    hidePlaceholder: PropTypes.bool
  }
  render () {
    return (
      <StyledDateTime
        closeOnSelect
        onChange={this.props.onChange}
        dateFormat={false}
        renderInput={(props) => {
          return (
            <Input
              {...props}
              value={this.props.value && this.props.value.format('hh:mm a')}
              onFocus={this.props.onFocus}
              placeholder={
                this.props.hidePlaceholder
                  ? null
                  : this.props.placeholder || 'Time'}
              normalPlaceholder='00 : 00'
              icon='Time'
              inputActive
            />
          )
        }}
      />
    )
  }
}

export default TimePicker
