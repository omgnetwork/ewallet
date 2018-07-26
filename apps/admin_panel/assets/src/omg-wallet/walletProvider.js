import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectWalletById } from './selector'
import { getWalletById } from './action'
import CONSTANT from '../constants'
class WalletProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    walletAddress: PropTypes.string,
    getWalletById: PropTypes.func,
    wallet: PropTypes.object
  }
  state = { loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT, result: {} }

  componentDidMount = () => {
    this.fetch()
  }
  componentWillReceiveProps = nextProps => {
    if (nextProps.walletAddress !== this.props.walletAddress) {
      this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT })
      this.fetch()
    }
  }
  fetch = async () => {
    if (this.props.walletAddress) {
      const result = await this.props.getWalletById(this.props.walletAddress)
      if (result.data) {
        this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.SUCCESS, result })
      } else {
        this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.FAILED, result })
      }
    }
  }
  render () {
    return this.props.render({
      wallet: this.props.wallet,
      loadingStatus: this.state.loadingStatus,
      result: this.state.result
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
