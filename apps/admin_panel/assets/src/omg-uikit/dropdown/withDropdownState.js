import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import clickOutside from '../../enhancer/clickOutside'
const WithDropdownState = BaseComponent => clickOutside(class extends PureComponent {
  static propTypes = {
    open: PropTypes.bool
  }
  static defaultProps = {
    data: []
  }

  state = {
    open: this.props.open || false
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
  stopPropagation = e => {
    e.stopPropagation()
    return false
  }
  render () {
    return <BaseComponent {...this.props} {...this.state} onClickButton={this.onClickButton} closeDropdown={this.closeDropdown} />
  }
})

export default WithDropdownState
