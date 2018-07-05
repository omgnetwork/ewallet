import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { Icon } from '../omg-uikit'
import { connect } from 'react-redux'
import { copyToClipboard } from './action'

class Copy extends Component {
  static propTypes = {
    data: PropTypes.string,
    copyToClipboard: PropTypes.func
  }
  onClickCopy = e => {
    e.stopPropagation()
    this.props.copyToClipboard(this.props.data)
  }

  render () {
    return <Icon name='Copy'onClick={this.onClickCopy} />
  }
}

export default connect(
  null,
  { copyToClipboard }
)(Copy)
