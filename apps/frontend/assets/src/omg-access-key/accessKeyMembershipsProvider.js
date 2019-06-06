import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

import { getAccessKeyMemberships } from './action'
import { assignKey, unassignKey } from '../omg-account/action'
import { selectAccessKeyMembershipsLoadingStatus, selectAccessKeyMemberships } from './selector'

// aka frontend ui -> "Admin Keys Assigned Accounts"
class AccessKeyMembershipsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    accessKeyId: PropTypes.string,
    filter: PropTypes.object,
    getAccessKeyMemberships: PropTypes.func,
    assignKey: PropTypes.func,
    unassignKey: PropTypes.func,
    memberships: PropTypes.array,
    membershipsLoadingStatus: PropTypes.string
  }

  componentDidMount = () => {
    this.fetch(this.props.filter)
  }

  UNSAFE_componentWillReceiveProps = nextProps => {
    if (!_.isEqual(nextProps.filter, this.props.filter)) {
      this.fetch(nextProps.filter)
    }
  }

  fetch = async filter => {
    return this.props.getAccessKeyMemberships({
      id: this.props.accessKeyId,
      ...filter
    })
  }

  render () {
    return this.props.render({
      refetch: this.fetch,
      memberships: this.props.memberships,
      membershipsLoading: this.props.membershipsLoadingStatus,
      updateRole: ({ accountId, role }) => this.props.assignKey({ keyId: this.props.accessKeyId, accountId, role }),
      removeAccount: ({ accountId }) => this.props.unassignKey({ keyId: this.props.accessKeyId, accountId })
    })
  }
}
export default connect(
  (state, props) => {
    return {
      membershipsLoadingStatus: selectAccessKeyMembershipsLoadingStatus(state),
      memberships: selectAccessKeyMemberships(state)(props.accessKeyId)
    }
  },
  { getAccessKeyMemberships, assignKey, unassignKey }
)(AccessKeyMembershipsProvider)
