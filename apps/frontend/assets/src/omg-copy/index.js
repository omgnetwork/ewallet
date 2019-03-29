import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { Icon } from '../omg-uikit'
import { connect } from 'react-redux'
import { copyToClipboard } from './action'
import styled from 'styled-components'
const IconButton = styled.span`
  cursor: pointer;
  vertical-align: middle;
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
