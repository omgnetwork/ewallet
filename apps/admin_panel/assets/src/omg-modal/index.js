import React, { Component } from 'react'
import PropTypes from 'prop-types'
import ReactModal from 'react-modal'

export default class Modal extends Component {
  static propTypes = {
    children: PropTypes.node.isRequired
  }

  render () {
    return (
      <ReactModal closeTimeoutMS={300}
        className='react-modal'
        overlayClassName='react-modal-overlay'
        {...this.props}
      >
        {this.props.children}
      </ReactModal>
    )
  }
}
