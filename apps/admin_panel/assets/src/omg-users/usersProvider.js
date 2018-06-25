import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectUsers, selectUsersLoadingStatus } from './selector'
import { getUsers } from './action'
class UsersProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    users: PropTypes.array,
    getUsers: PropTypes.func,
    usersLoadingStatus: PropTypes.string,
    search: PropTypes.string,
    page: PropTypes.number,
    perPage: PropTypes.number
  }
  getUser = () => {
    this.props.getUsers({
      page: this.props.page,
      search: this.props.search,
      perPage: this.props.perPage
    })
  }
  componentWillReceiveProps = nextProps => {
    if (this.props.search !== nextProps.search || this.props.page !== nextProps.page) {
      this.getUser()
    }
  }

  componentDidMount = () => {
    this.getUser()
  }
  render () {
    return this.props.render({
      users: this.props.users,
      loadingStatus: this.props.usersLoadingStatus
    })
  }
}
export default connect(
  (state, props) => {
    return {
      users: selectUsers(state, props.search),
      usersLoadingStatus: selectUsersLoadingStatus(state)
    }
  },
  { getUsers }
)(UsersProvider)
