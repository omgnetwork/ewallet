import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectWalletById } from './selector'
import { getWalletById } from './action'
class WalletProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    walletId: PropTypes.string,
    getWalletById: PropTypes.func,
    wallet: PropTypes.object
  }

  componentDidMount = () => {
    if (!this.props.wallet) {
      this.props.getWalletById(this.props.walletId)
    }
  }
  render () {
    return this.props.render({
      wallet: this.props.wallet
    })
  }
}
export default connect(
  (state, props) => {
    return {
      wallet: selectWalletById(props.walletId)(state)
    }
  },
  { getWalletById }
)(WalletProvider)
