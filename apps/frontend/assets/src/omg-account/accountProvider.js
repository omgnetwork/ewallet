import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectGetAccountById } from './selector'
import { getAccountById } from './action'
class AccountsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    accountId: PropTypes.string,
    account: PropTypes.object,
    getAccountById: PropTypes.func
  }

  componentDidMount () {
    this.props.getAccountById(this.props.accountId)
  }

  UNSAFE_componentWillReceiveProps = nextProps => {
    if (nextProps.accountId !== this.props.accountId) {
      this.props.getAccountById(nextProps.accountId)
    }
  }

  render () {
    return this.props.render({ account: this.props.account })
  }
}
export default connect(
  (state, props) => {
    return {
      account: selectGetAccountById(state)(props.accountId)
    }
  },
  { getAccountById }
)(AccountsProvider)
