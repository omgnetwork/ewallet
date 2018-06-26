import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import CONSTANT from '../constants'
import { getUsers } from './action'
class UsersFetcher extends Component {
  static propTypes = {
    render: PropTypes.func,
    users: PropTypes.array,
    getUsers: PropTypes.func,
    usersLoadingStatus: PropTypes.string,
    search: PropTypes.string,
    page: PropTypes.number,
    perPage: PropTypes.number,
    onFetchComplete: PropTypes.func
  }
  state = { users: [], loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT, pagination: {} }
  componentDidMount = () => {
    this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.INITIATED })
    this.fetch()
  }
  componentDidUpdate = nextProps => {
    if (this.props.search !== nextProps.search || this.props.page !== nextProps.page) {
      this.fetch()
    }
  }
  fetch = async () => {
    try {
      const { users, pagination, error } = await this.props.getUsers({
        page: this.props.page,
        search: this.props.search,
        perPage: this.props.perPage
      })
      if (users) {
        this.setState({
          users,
          loadingStatus: CONSTANT.LOADING_STATUS.SUCCESS,
          pagination
        })
        this.props.onFetchComplete()
      } else {
        this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.FAILED, error })
      }
    } catch (e) {
      this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.FAILED, error: e })
    }
  }

  render () {
    return this.props.render({
      users: this.state.users,
      loadingStatus: this.state.loadingStatus,
      pagination: this.state.pagination
    })
  }
}
export default connect(
  null,
  { getUsers }
)(UsersFetcher)
