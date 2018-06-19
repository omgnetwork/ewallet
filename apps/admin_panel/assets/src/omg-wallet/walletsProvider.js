import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectWalletsByAccountId, selectWalletsLoadingStatus } from './selector'
import { getWalletsByAccountId } from './action'
class WalletProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    wallets: PropTypes.array,
    getWalletsByAccountId: PropTypes.func,
    walletsLoadingStatus: PropTypes.string,
    search: PropTypes.string,
    accountId: PropTypes.string
  }
  componentWillReceiveProps = nextProps => {
    if (this.props.search !== nextProps.search) {
      this.props.getWalletsByAccountId({
        accountId: this.props.accountId,
        search: this.props.search
      })
    }
  }

  componentDidMount = () => {
    if (this.props.walletsLoadingStatus === 'DEFAULT') {
      this.props.getWalletsByAccountId({
        accountId: this.props.accountId,
        search: this.props.search
      })
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
      wallets: selectWalletsByAccountId(state, props.search, props.accountId),
      walletsLoadingStatus: selectWalletsLoadingStatus(state)
    }
  },
  { getWalletsByAccountId }
)(WalletProvider)
