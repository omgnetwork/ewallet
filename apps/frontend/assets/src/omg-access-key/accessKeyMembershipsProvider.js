import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

import { getAccessKeyMemberships } from './action'
import { assignKey, unassignKey } from '../omg-account/action'
import {
  selectAccessKeyMemberships
} from './selector'

import CONSTANT from '../constants'
// aka frontend ui -> "Admin Keys Assigned Accounts"
class AccessKeyMembershipsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    accessKeyId: PropTypes.string,
    filter: PropTypes.object,
    getAccessKeyMemberships: PropTypes.func,
    assignKey: PropTypes.func,
    unassignKey: PropTypes.func,
    memberships: PropTypes.array
  }

  state = {
    loadingSatus: CONSTANT.LOADING_STATUS.DEFAULT
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
    this.setState({ loadingSatus: CONSTANT.LOADING_STATUS.INITIATED })
    return this.props
      .getAccessKeyMemberships({
        id: this.props.accessKeyId,
        ...filter
      })
      .then(({ data }) => {
        if (data) {
          this.setState({ loadingSatus: CONSTANT.LOADING_STATUS.SUCCESS })
        } else {
          this.setState({ loadingSatus: CONSTANT.LOADING_STATUS.FAILED })
        }
      })
  }

  render () {
    return this.props.render({
      refetch: this.fetch,
      memberships: this.props.memberships,
      membershipsLoading: this.state.loadingSatus,
      updateRole: ({ accountId, role }) =>
        this.props.assignKey({
          keyId: this.props.accessKeyId,
          accountId,
          role
        }),
      removeAccount: ({ accountId }) =>
        this.props.unassignKey({ keyId: this.props.accessKeyId, accountId })
    })
  }
}
export default connect(
  (state, props) => {
    return {
      memberships: selectAccessKeyMemberships(state)(props.accessKeyId)
    }
  },
  { getAccessKeyMemberships, assignKey, unassignKey }
)(AccessKeyMembershipsProvider)
