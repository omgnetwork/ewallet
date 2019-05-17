import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import styled from 'styled-components'

import { Icon } from '../omg-uikit'
import { copyToClipboard } from './action'

const IconButton = styled.span`
  cursor: pointer;
  color: ${props => props.theme.colors.S500};
  :hover {
    color: ${props => props.theme.colors.B300};
  }
`
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
    return (
      <IconButton>
        <Icon name='Copy' onClick={this.onClickCopy} />
      </IconButton>
    )
  }
}

export default connect(
  null,
  { copyToClipboard }
)(Copy)
