import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { getTransactions } from './action'
import { compose } from 'recompose'
import CONSTANT from '../constants'
const ehance = compose(
  connect(
    null,
    { getTransactions }
  )
)
class TransactionsFetcher extends Component {
  static propTypes = {
    render: PropTypes.func,
    getTransactions: PropTypes.func,
    search: PropTypes.string,
    page: PropTypes.number,
    perPage: PropTypes.number,
    onFetchComplete: PropTypes.func
  }
  state = {
    loadingStatus: 'DEFAULT',
    transactions: [],
    pagination: {}
  }
  componentDidUpdate = nextProps => {
    if (this.props.search !== nextProps.search || this.props.page !== nextProps.page) {
      this.fetch()
    }
  }
  fetch = async () => {
    try {
      const { transactions, error, pagination } = await this.props.getTransactions({
        page: this.props.page || 1,
        search: this.props.search,
        perPage: this.props.perPage
      })
      if (transactions) {
        this.setState({
          transactions,
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

  componentDidMount = async () => {
    this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.INITIATED })
    this.fetch()
  }
  render () {
    return this.props.render({
      transactions: this.state.transactions,
      loadingStatus: this.state.loadingStatus,
      pagination: this.state.pagination
    })
  }
}
export default ehance(TransactionsFetcher)
