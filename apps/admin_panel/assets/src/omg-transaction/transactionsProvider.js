import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectTransactions, selectTransactionsLoadingStatus } from './selector'
import { getTransactions } from './action'
import { compose } from 'recompose'
const ehance = compose(
  connect(
    (state, props) => {
      return {
        transactions: selectTransactions(state, props.search),
        transactionsLoadingStatus: selectTransactionsLoadingStatus(state)
      }
    },
    { getTransactions }
  )
)
import CONSTANT from '../constants'
class TransactionsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    transactions: PropTypes.array,
    getTransactions: PropTypes.func,
    transactionsLoadingStatus: PropTypes.string,
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
