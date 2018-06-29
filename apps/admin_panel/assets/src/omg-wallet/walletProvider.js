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
    wallet: PropTypes.object
  }

  componentDidMount = () => {
    this.props.getWalletById(this.props.walletAddress)
  }
  componentWillReceiveProps = nextProps => {
    if (nextProps.walletAddress !== this.props.walletAddress) {
      this.props.getWalletById(nextProps.walletAddress)
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
      wallet: selectWalletById(state)(props.walletAddress)
    }
  },
  { getWalletById }
)(WalletProvider)
