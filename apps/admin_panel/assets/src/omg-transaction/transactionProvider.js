import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectGetTransactionById } from './selector'
import { getTransactionById } from './action'
class TransactionProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    transactionId: PropTypes.string,
    transaction: PropTypes.object,
    getTransactionById: PropTypes.func
  }

  componentDidMount = () => {
    if (_.isEmpty(this.props.transaction)) {
      this.props.getTransactionById(this.props.transactionId)
    }
  }
  render () {
    return this.props.render({
      transaction: this.props.transaction
    })
  }
}
export default connect(
  (state, props) => {
    return {
      transaction: selectGetTransactionById(state)(props.transactionId)
    }
  },
  { getTransactionById }
)(TransactionProvider)
