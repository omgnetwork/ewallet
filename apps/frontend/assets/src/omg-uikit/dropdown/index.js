import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import clickOutside from '../../enhancer/clickOutside'

export const DropdownBox = styled.div`
  border: 1px solid #ebeff7;
  border-radius: 2px;
  box-shadow: 0 4px 12px 0 #e8eaed;
  background-color: white;
  right: 0;
  max-height: 200px;
  overflow: auto;
`
export const DropdownBoxItem = styled.div`
  padding: 10px 20px;
  cursor: pointer;
  font-size: 12px;
  font-weight: 300;
  :hover {
    background-color: ${props => props.theme.colors.S200};
  }
  :active {
    background-color: ${props => props.theme.colors.S400};
  }
  :first-child {
    border-bottom: 1px solid ${props => props.theme.colors.S400};
  }
`
class Dropdown extends PureComponent {
  static propTypes = {
    render: PropTypes.func,
    onSelect: PropTypes.func,
    open: PropTypes.bool,
    data: PropTypes.array,
    defaultSelected: PropTypes.string
  }
  static defaultProps = {
    data: []
  }

  state = {
    open: this.props.open || false,
    selectedItem: this.props.defaultSelected
  }

  handleClickOutside = e => {
    this.closeDropdown()
  }

  onClickButton = e => {
    this.setState(({ open }) => ({ open: !open }))
  }
  closeDropdown = () => {
    this.setState({ open: false })
  }
  openDropdown = () => {
    this.setState({ open: true })
  }
  handleClickOutside = () => {
    this.closeDropdown()
  }
  onSelect = (key, data) => e => {
    this.setState({ selectedItem: key })
    this.props.onSelect(key, data)
    this.closeDropdown()
  }
  stopPropagation = e => {
    e.stopPropagation()
    return false
  }
  render () {
    const dropdownBox = (
      <DropdownBox open={this.state.open} onClick={this.stopPropagation}>
        {this.props.data.map((item, i) => (
          <DropdownBoxItem key={i} onClick={this.onSelect(item)}>
            {item}
          </DropdownBoxItem>
        ))}
      </DropdownBox>
    )
    return this.props.render({
      open: this.state.open,
      onClickButton: this.onClickButton,
      dropdownBox: dropdownBox,
      selectedItem: this.state.selectedItem,
      closeDropdown: this.closeDropdown
    })
  }
}

export default clickOutside(Dropdown)
