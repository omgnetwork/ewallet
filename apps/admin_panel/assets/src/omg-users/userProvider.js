import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectUser } from './selector'
import { getUserById } from './action'
class UserProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    userId: PropTypes.string,
    user: PropTypes.object,
    getUserById: PropTypes.func
  }

  componentDidMount = () => {
    if (!this.props.user) {
      this.props.getUserById(this.props.userId)
    }
  }
  render () {
    return this.props.render({
      user: this.props.user
    })
  }
}
export default connect(
  (state, props) => {
    return {
      user: selectUser(props.userId)(state)
    }
  },
  { getUserById }
)(UserProvider)
