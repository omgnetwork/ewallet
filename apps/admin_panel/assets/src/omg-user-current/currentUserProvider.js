import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectCurrentUser, selectCurrentUserLoadingStatus } from './selector'
import { getCurrentUser } from './action'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'
import { removeAccessDataFromLocalStorage } from '../services/sessionService'
class UserProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    currentUser: PropTypes.object,
    getCurrentUser: PropTypes.func,
    currentUserLoadingStatus: PropTypes.string,
    history: PropTypes.object
  }
  componentDidMount = async () => {
    if (this.props.currentUserLoadingStatus === 'DEFAULT') {
      const result = await this.props.getCurrentUser()
      if (!result.data.success) {
        this.props.history.push('/login')
        removeAccessDataFromLocalStorage()
      }
    }
  }
  render () {
    return this.props.render({
      currentUser: this.props.currentUser,
      loadingStatus: this.props.currentUserLoadingStatus
    })
  }
}

const EnhancedUserProvider = compose(
  withRouter,
  connect(
    (state, props) => {
      return {
        currentUser: selectCurrentUser(state),
        currentUserLoadingStatus: selectCurrentUserLoadingStatus(state)
      }
    },
    { getCurrentUser }
  )
)(UserProvider)

export const currentUserProviderHoc = BaseComponent =>
  class extends Component {
    renderBaseComponent = ({ currentUser, loadingStatus }) => {
      return (
        <BaseComponent {...this.props} currentUser={currentUser} loadingStatus={loadingStatus} />
      )
    }
    render () {
      return <EnhancedUserProvider render={this.renderBaseComponent} />
    }
  }

export default EnhancedUserProvider
