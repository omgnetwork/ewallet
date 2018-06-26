import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { getWalletsByAccountId } from './action'
import CONSTANT from '../constants'
import { selectWallets } from './selector'
class WalletsFetcher extends Component {
  static propTypes = {
    render: PropTypes.func,
    wallets: PropTypes.array,
    getWalletsByAccountId: PropTypes.func,
    walletsLoadingStatus: PropTypes.string,
    search: PropTypes.string,
    page: PropTypes.number,
    accountId: PropTypes.string,
    onFetchComplete: PropTypes.func
  }
  state = {
    wallets: [],
    pagination: {},
    loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT
  }
  fetch = async () => {
    try {
      const { wallets, pagination, error } = await this.props.getWalletsByAccountId({
        accountId: this.props.accountId,
        search: this.props.search,
        page: this.props.page || 1,
        perPage: this.props.perPage
      })
      if (wallets) {
        this.setState({
          wallets,
          loadingStatus: CONSTANT.LOADING_STATUS.SUCCESS,
          pagination
        })
        this.props.onFetchComplete()
      } else {
        this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.FAILED, error })
      }
    } catch (e) {
      this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.FAILED, error: e })
    }
  }
  componentDidUpdate = nextProps => {
    if (this.props.search !== nextProps.search || this.props.page !== nextProps.page) {
      this.fetch()
    }
  }
  componentDidMount = () => {
    this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.INITIATED })
    this.fetch()
  }
  render () {
    return this.props.render({
      wallets: selectWallets({ wallets: this.state.wallets }, this.props.search),
      loadingStatus: this.state.loadingStatus,
      pagination: this.state.pagination
    })
  }
}
export default connect(
  null,
  { getWalletsByAccountId }
)(WalletsFetcher)
