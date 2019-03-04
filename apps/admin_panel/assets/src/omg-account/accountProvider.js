import { Component, useState, useEffect } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectGetAccountById } from './selector'
import { getAccountById } from './action'
import { store } from '../store'
import CONSTANT from '../constants'
class AccountsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    accountId: PropTypes.string,
    account: PropTypes.object,
    getAccountById: PropTypes.func
  }
  componentDidMount = () => {
    this.props.getAccountById(this.props.accountId)
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

// HOOK EXPERIMENTING
export function useAccount (accountId) {
  const defaultAccount = selectGetAccountById(store.getState())(accountId)
  const [account, setAccount] = useState(defaultAccount)
  const [loadingStatus, setLoadingStatus] = useState(
    _.isEmpty(defaultAccount) ? CONSTANT.LOADING_STATUS.DEFAULT : CONSTANT.LOADING_STATUS.SUCCESS
  )
  function handleLoadingStatusChange (result) {
    setAccount(result.data)
    setLoadingStatus(result.data ? CONSTANT.LOADING_STATUS.SUCCESS : CONSTANT.LOADING_STATUS.FAILED)
  }

  useEffect(() => {
    if (loadingStatus !== CONSTANT.LOADING_STATUS.SUCCESS) {
      getAccountById(accountId)(store.dispatch).then(handleLoadingStatusChange)
    }
  }, [accountId])

  return { account, loadingStatus }
}
