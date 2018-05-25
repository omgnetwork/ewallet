import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectInviteList, selectInviteListLoadingStatus } from './selector'
import { getListMembers } from './action'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'
class InviteListProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    inviteList: PropTypes.array,
    getListMembers: PropTypes.func,
    inviteListLoadingStatus: PropTypes.string,
    match: PropTypes.object
  }
  componentDidMount = () => {
    if (this.props.inviteListLoadingStatus === 'DEFAULT') {
      this.props.getListMembers(this.props.match.params.accountId)
    }
  }
  render () {
    return this.props.render({ inviteList: this.props.inviteList, loadingStatus: this.props.inviteListLoadingStatus })
  }
}

const enhance = compose(
  connect(
    state => {
      return {
        inviteList: selectInviteList(state),
        inviteListLoadingStatus: selectInviteListLoadingStatus(state)
      }
    },
    { getListMembers }
  ),
  withRouter
)
export default enhance(InviteListProvider)
