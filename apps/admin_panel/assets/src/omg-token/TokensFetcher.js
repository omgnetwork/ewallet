import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import CONSTANT from '../constants'
import { loadTokens } from './action'
class TokensFetcher extends Component {
  static propTypes = {
    render: PropTypes.func,
    loadTokens: PropTypes.func,
    search: PropTypes.string,
    page: PropTypes.number,
    perPage: PropTypes.number,
    onFetchComplete: PropTypes.func
  }
  state = { tokens: [], loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT, pagination: {} }
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
      const { tokens, pagination, error } = await this.props.loadTokens({
        page: this.props.page,
        search: this.props.search,
        perPage: this.props.perPage
      })
      if (tokens) {
        this.setState({
          tokens,
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
      tokens: this.state.tokens,
      loadingStatus: this.state.loadingStatus,
      pagination: this.state.pagination
    })
  }
}
export default connect(
  null,
  { loadTokens }
)(TokensFetcher)
