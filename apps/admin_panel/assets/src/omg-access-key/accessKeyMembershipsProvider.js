import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

import { selectGetAccessKeyById } from './selector'
import { getAccessKeyMemberships } from './action'

// aka frontend ui -> "Admin Keys Assigned Accounts"
class AccessKeyMembershipsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    accessKeyId: PropTypes.string,
    memberships: PropTypes.object,
    getAccessKeyMemberships: PropTypes.func
  }

  componentDidMount = () => {
    if (!this.props.memberships) {
      this.props.getAccessKeyMemberships(this.props.accessKeyId)
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
      memberships: selectGetAccessKeyById(state)(props.accessKeyId)
    }
  },
  { getAccessKeyMemberships }
)(AccessKeyMembershipsProvider)
