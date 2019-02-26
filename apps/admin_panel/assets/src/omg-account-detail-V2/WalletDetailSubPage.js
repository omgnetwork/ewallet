import React, { Component } from 'react'
import PropTypes from 'prop-types'
import WalletDetailPage from '../omg-page-wallet-detail'
export default class WalletDetailSubPage extends Component {
  static propTypes = {
    prop: PropTypes
  }

  render () {
    return <WalletDetailPage />
  }
}
