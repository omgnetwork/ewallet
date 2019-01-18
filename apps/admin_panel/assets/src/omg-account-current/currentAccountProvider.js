import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectCurrentAccount, selectCurrentAccountLoadingStatus } from './selector'
import { getCurrentAccount } from './action'
import { withRouter } from 'react-router-dom'
class CurrentAccountProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    currentAccount: PropTypes.object,
    getCurrentAccount: PropTypes.func,
    currentAccountLoadingStatus: PropTypes.string,
    match: PropTypes.object
  }
  componentDidMount = () => {
    if (this.props.currentAccountLoadingStatus !== 'SUCCESS') {
      this.props.getCurrentAccount(this.props.match.params.accountId)
    }
  }
  render () {
    return this.props.render({
      currentAccount: this.props.currentAccount,
      loadingStatus: this.props.currentAccountLoadingStatus
    })
  }
}
const EnhancedCurrentAccountProvider = connect(
  (state, props) => {
    return {
      currentAccount: selectCurrentAccount(state),
      currentAccountLoadingStatus: selectCurrentAccountLoadingStatus(state)
    }
  },
  { getCurrentAccount }
)(withRouter(CurrentAccountProvider))

export const currentAccountProviderHoc = BaseComponent =>
  class extends Component {
    renderBaseComponent = ({ currentAccount, loadingStatus }) => {
      return (
        <BaseComponent
          {...this.props}
          currentAccount={currentAccount}
          loadingStatus={loadingStatus}
        />
      )
    }
    render () {
      return <EnhancedCurrentAccountProvider render={this.renderBaseComponent} {...this.props} />
    }
  }

export default EnhancedCurrentAccountProvider
