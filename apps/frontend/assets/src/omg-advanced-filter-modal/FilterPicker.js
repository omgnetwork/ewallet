import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'

import PopperRenderer from '../omg-popper'
import withDropdownState from '../omg-uikit/dropdown/withDropdownState'
import { Icon } from '../omg-uikit'
import { DropdownBox } from '../omg-uikit/dropdown'

const FilterPickerStyles = styled.div`
  margin: 20px 0;
  color: ${props => props.theme.colors.BL400};
  display: inline-flex;
  align-items: center;
  cursor: pointer;
  i {
    margin-right: 5px;
  }
`
const DropdownItem = styled.div`
  padding: 7px 10px;
  padding-right: 20px;
  font-size: 12px;
  color: ${props => props.theme.colors.B100};
  cursor: pointer;
  i,
  span {
    vertical-align: middle;
    display: inline-block;
  }
  :hover {
    color: ${props => props.theme.colors.B400};
  }
  i {
    margin-right: 5px;
  }
`

const renderFilterOptions = (page) => {
  switch (page) {
    case 'transaction':
      return (
        <DropdownBox>
          <DropdownItem onClick={console.log}>
            <Icon name='Wallet' />
            <span>Account Wallets</span>
          </DropdownItem>
          <DropdownItem onClick={console.log}>
            <Icon name='Wallet' />
            <span>Users Wallets</span>
          </DropdownItem>
        </DropdownBox>
      )
    default:
  }
}

const FilterPicker = ({ page, open, onClickButton, ...rest }) => {
  return (
    <PopperRenderer
      offset='0, -10px'
      modifiers={{
        flip: {
          enabled: false
        }
      }}
      renderReference={() => (
        <FilterPickerStyles onClick={onClickButton}>
          <Icon name='Plus' />
          <span>Add filter</span>
        </FilterPickerStyles>
      )}
      open={open}
      renderPopper={() => renderFilterOptions(page)}
    />
  )
}

FilterPicker.propTypes = {
  page: PropTypes.oneOf(['transaction']),
  open: PropTypes.bool,
  onClickButton: PropTypes.func.isRequired
}

export default withDropdownState(FilterPicker)
