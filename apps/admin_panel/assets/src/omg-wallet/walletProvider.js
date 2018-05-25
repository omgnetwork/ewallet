import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectWallets, selectWalletsLoadingStatus } from './selector'
import { getWallets } from './action'
class WalletProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    wallets: PropTypes.array,
    getWallets: PropTypes.func,
    walletsLoadingStatus: PropTypes.string,
    search: PropTypes.string
  }
  componentWillReceiveProps = nextProps => {
    if (this.props.search !== nextProps.search) {
      this.props.getWallets(nextProps.search)
    }
  }

  componentDidMount = () => {
    if (this.props.walletsLoadingStatus === 'DEFAULT') {
      this.props.getWallets()
    }
  }
  render () {
    return this.props.render({
      wallets: this.props.wallets,
      loadingStatus: this.props.walletsLoadingStatus
    })
  }
}
export default connect(
  (state, props) => {
    return {
      wallets: selectWallets(state, props.search),
      walletsLoadingStatus: selectWalletsLoadingStatus(state)
    }
  },
  { getWallets }
)(WalletProvider)
