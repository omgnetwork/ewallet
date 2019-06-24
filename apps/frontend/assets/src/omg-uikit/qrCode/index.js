import QRCode from 'qrcode'
import React, { Component } from 'react'
import PropTypes from 'prop-types'

export default class QR extends Component {
  static propTypes = {
    data: PropTypes.string,
    size: PropTypes.oneOfType([PropTypes.string, PropTypes.number])
  }
  state = {}
  componentDidMount = async () => {
    if (this.props.data) {
      const dataUrl = await QRCode.toDataURL(this.props.data)
      this.setState({ dataUrl })
    }
  }
  componentDidUpdate = async nextProps => {
    if (this.props.data !== nextProps.data) {
      const dataUrl = await QRCode.toDataURL(this.props.data)
      this.setState({ dataUrl })
    }
  }
  render () {
    return (
      <img
        src={this.state.dataUrl}
        style={{ width: this.props.size, height: this.props.size }}
      />
    )
  }
}
