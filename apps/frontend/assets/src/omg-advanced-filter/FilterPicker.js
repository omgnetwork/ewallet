import React from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { difference } from 'lodash'

import PopperRenderer from '../omg-popper'
import withDropdownState from '../omg-uikit/dropdown/withDropdownState'
import { Icon } from '../omg-uikit'
import { DropdownBox } from '../omg-uikit/dropdown'

import { FILTER_MAP } from './FilterMap'

const FilterPickerStyles = styled.div`
  margin: 20px 0;
  color: ${props => props.theme.colors.BL400};
  display: inline-flex;
  align-items: center;
  height: 20px;
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
    background-color: ${props => props.theme.colors.S100};
  }
  i {
    margin-right: 10px;
  }
`
const DropdownBoxStyles = styled(DropdownBox)`
  transform: translateX(100%);
  width: 220px;
`

const FilterPicker = ({
  page,
  open,
  onClickButton,
  onSelect,
  selectedFilters
}) => {
  const diff = difference(FILTER_MAP.filter(i => i.page === page), selectedFilters)
  return (
    <PopperRenderer
      offset='-100%, -10px'
      modifiers={{
        flip: {
          enabled: false
        }
      }}
      renderReference={() => (
        <FilterPickerStyles onClick={onClickButton}>
          {diff.length ? <Icon name='Plus' /> : null}
          <span>{diff.length ? 'Add filter' : ''}</span>
        </FilterPickerStyles>
      )}
      open={diff.length ? open : false}
      renderPopper={() => {
        return (
          <DropdownBoxStyles>
            {diff.map(filter => (
              <DropdownItem
                key={filter.key}
                onClick={() => onSelect(filter)}
              >
                <Icon name={filter.icon} />
                <span>{filter.title}</span>
              </DropdownItem>
            ))}
          </DropdownBoxStyles>
        )
      }}
    />
  )
}

FilterPicker.propTypes = {
  page: PropTypes.string,
  open: PropTypes.bool,
  onClickButton: PropTypes.func.isRequired,
  onSelect: PropTypes.func.isRequired,
  selectedFilters: PropTypes.arrayOf(PropTypes.object)
}

export default withDropdownState(FilterPicker)
