import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectAccounts, selectAccountsLoadingStatus } from './selector'
import { getAccounts } from './action'
class AccountsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    accounts: PropTypes.array,
    getAccounts: PropTypes.func,
    search: PropTypes.string,
    accountsLoadingStatus: PropTypes.string
  }
  componentWillReceiveProps = async nextProps => {
    if (this.props.search !== nextProps.search) {
      this.props.getAccounts(nextProps.search)
    }
  }

  componentDidMount = () => {
    if (this.props.accountsLoadingStatus === 'DEFAULT') {
      this.props.getAccounts()
    }
  }
  render () {
    return this.props.render({
      accounts: this.props.accounts,
      loadingStatus: this.props.accountsLoadingStatus
    })
  }
}
export default connect(
  (state, props) => {
    return {
      accounts: selectAccounts(state, props.search),
      accountsLoadingStatus: selectAccountsLoadingStatus(state)
    }
  },
  { getAccounts }
)(AccountsProvider)
