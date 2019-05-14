import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

import { getAccessKeyMemberships } from './action'

// aka frontend ui -> "Admin Keys Assigned Accounts"
class AccessKeyMembershipsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    accessKeyId: PropTypes.string,
    filter: PropTypes.object,
    // memberships: PropTypes.object,
    getAccessKeyMemberships: PropTypes.func
  }

  state = {
    memberships: [],
    loading: ''
  }

  componentDidMount = () => {
    if (!this.state.memberships.length) {
      this.fetch(this.props.filter)
    }
  }

  UNSAFE_componentWillReceiveProps = nextProps => {
    if (!_.isEqual(nextProps.filter, this.props.filter)) {
      this.fetch(nextProps.filter)
    }
  }

  fetch = async filter => {
    this.setState({ loading: 'INITIATED' })
    const res = await this.props.getAccessKeyMemberships({
      id: this.props.accessKeyId,
      ...filter
    })
    this.setState({ memberships: res.data, loading: '' })
  }

  render () {
    return this.props.render({
      memberships: this.state.memberships,
      loading: this.state.loading
    })
  }
}
export default connect(
  null,
  { getAccessKeyMemberships }
)(AccessKeyMembershipsProvider)
