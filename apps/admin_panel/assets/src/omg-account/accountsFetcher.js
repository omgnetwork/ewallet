import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import CONSTANT from '../constants'
import { getAccounts } from './action'
class AccountsFetcher extends Component {
  static propTypes = {
    render: PropTypes.func,
    loadTokens: PropTypes.func,
    search: PropTypes.string,
    page: PropTypes.number,
    perPage: PropTypes.number,
    onFetchComplete: PropTypes.func
  }
  state = { accounts: [], loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT, pagination: {} }
  componentDidMount = () => {
    this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.INITIATED })
    this.fetch()
  }
  componentDidUpdate = nextProps => {
    if (this.props.search !== nextProps.search || this.props.page !== nextProps.page) {
      this.fetch()
    }
  }
  fetch = async () => {
    try {
      const { accounts, pagination, error } = await this.props.getAccounts({
        page: this.props.page,
        search: this.props.search,
        perPage: this.props.perPage
      })
      if (accounts) {
        this.setState({
          accounts,
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

  render () {
    return this.props.render({
      accounts: this.state.accounts,
      loadingStatus: this.state.loadingStatus,
      pagination: this.state.pagination
    })
  }
}
export default connect(
  null,
  { getAccounts }
)(AccountsFetcher)
