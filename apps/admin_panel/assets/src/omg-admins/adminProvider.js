import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectAdmin } from './selector'
import { getAdminById } from './action'
class AdminProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    adminId: PropTypes.string,
    admin: PropTypes.object,
    getAdminById: PropTypes.func
  }

  componentDidMount = () => {
    if (!this.props.admin) {
      this.props.getAdminById(this.props.adminId)
    }
  }
  render () {
    return this.props.render({
      admin: this.props.admin
    })
  }
}
export default connect(
  (state, props) => {
    return {
      admin: selectAdmin(props.adminId)(state)
    }
  },
  { getAdminById }
)(AdminProvider)
