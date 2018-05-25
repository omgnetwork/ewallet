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
class AccountsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    transactions: PropTypes.array,
    getTransactions: PropTypes.func,
    transactionsLoadingStatus: PropTypes.string,
    search: PropTypes.string
  }
  componentWillReceiveProps = nextProps => {
    if (this.props.search !== nextProps.search) {
      this.props.getTransactions(nextProps.search)
    }
  }

  componentDidMount = () => {
    if (this.props.transactionsLoadingStatus === 'DEFAULT') {
      this.props.getTransactions()
    }
  }
  render () {
    return this.props.render({
      transactions: this.props.transactions,
      loadingStatus: this.props.transactionsLoadingStatus
    })
  }
}
export default ehance(AccountsProvider)
