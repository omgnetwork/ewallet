import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

import { selectAccessKeyMemberships, selectAccessKeyMembershipsLoadingStatus } from './selector'
import { getAccessKeyMemberships } from './action'

// aka frontend ui -> "Admin Keys Assigned Accounts"
class AccessKeyMembershipsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    accessKeyId: PropTypes.string,
    filter: PropTypes.object,
    memberships: PropTypes.object,
    getAccessKeyMemberships: PropTypes.func
  }

  componentDidMount = () => {
    if (!this.props.memberships) {
      this.props.getAccessKeyMemberships({
        id: this.props.accessKeyId,
        ...this.props.filter
      })
    }
  }
  render () {
    return this.props.render({
      memberships: this.props.memberships
    })
  }
}
export default connect(
  (state, props) => {
    return {
      memberships: selectAccessKeyMemberships(state)(props.accessKeyId),
      loading: selectAccessKeyMembershipsLoadingStatus(state)
    }
  },
  { getAccessKeyMemberships }
)(AccessKeyMembershipsProvider)
