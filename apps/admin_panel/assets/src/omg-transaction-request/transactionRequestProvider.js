import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectGetTransactionRequestById } from './selector'
import { getTransactionRequestById } from './action'
class TransactionRequestProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    transactionRequestId: PropTypes.string,
    transactionRequest: PropTypes.object,
    getTransactionRequestById: PropTypes.func
  }

  componentDidMount = () => {
    if (!this.props.transactionRequest) {
      this.props.getTransactionRequestById(this.props.transactionRequestId)
    }
  }
  render () {
    return this.props.render({
      transactionRequest: this.props.transactionRequest
    })
  }
}
export default connect(
  (state, props) => {
    return {
      transactionRequest: selectGetTransactionRequestById(state)(props.transactionRequestId)
    }
  },
  { getTransactionRequestById }
)(TransactionRequestProvider)
