import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectGetAccountById, selectAccountsLoadingStatus } from './selector'
import { getAccounts } from './action'
class AccountsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    accountId: PropTypes.string,
    account: PropTypes.object,
    getAccounts: PropTypes.func,
    accountsLoadingStatus: PropTypes.string
  }
  componentDidMount = () => {
    if (this.props.accountsLoadingStatus === 'DEFAULT') {
      this.props.getAccounts()
    }
  }
  render () {
    return this.props.render({ account: this.props.account, loadingStatus: this.props.accountsLoadingStatus })
  }
}
export default connect((state, props) => {
  return {
    account: selectGetAccountById(state)(props.accountId),
    accountsLoadingStatus: selectAccountsLoadingStatus(state)
  }
}, { getAccounts })(AccountsProvider)
