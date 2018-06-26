import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { getTransactions } from './action'
import { compose } from 'recompose'
const ehance = compose(
  connect(
    null,
    { getTransactions }
  )
)
import CONSTANT from '../constants'
class TransactionsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    getTransactions: PropTypes.func,
    search: PropTypes.string,
    page: PropTypes.number,
    perPage: PropTypes.number
  }
  state = {
    loadingStatus: 'DEFAULT',
    transactions: []
  }
  componentDidUpdate = nextProps => {
    if (this.props.search !== nextProps.search || this.props.page !== nextProps.page) {
      this.fetch()
    }
  }
  fetch = async () => {
    try {
      const { transactions, error } = await this.props.getTransactions({
        page: this.props.page,
        search: this.props.search,
        perPage: this.props.perPage
      })
      if (transactions) {
        this.setState({
          transactions: transactions.data,
          loadingStatus: CONSTANT.LOADING_STATUS.SUCCESS
        })
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
      loadingStatus: this.state.loadingStatus
    })
  }
}
export default ehance(TransactionsProvider)
