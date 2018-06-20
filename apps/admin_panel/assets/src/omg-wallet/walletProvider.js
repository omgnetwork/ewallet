import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectWalletById } from './selector'
import { getWalletById } from './action'
class WalletProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    walletAddress: PropTypes.string,
    getWalletById: PropTypes.func,
    wallet: PropTypes.object,
    pooling: PropTypes.bool
  }

  componentDidMount = () => {
    if (!this.props.wallet) {
      this.props.getWalletById(this.props.walletAddress)
    }
    if (this.props.pooling) {
      setInterval(() => {
        this.props.getWalletById(this.props.walletAddress)
      }, 5000)
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
      wallet: selectWalletById(props.walletAddress)(state)
    }
  },
  { getWalletById }
)(WalletProvider)
