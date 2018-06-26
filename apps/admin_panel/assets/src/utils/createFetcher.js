import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import CONSTANT from '../constants'
export const createFetcher = (reducer, selectors) =>
  connect(selectors,
    { dispatcher: reducer }
  )(
    class Fetcher extends Component {
      static propTypes = {
        render: PropTypes.func,
        search: PropTypes.string,
        page: PropTypes.number,
        perPage: PropTypes.number,
        onFetchComplete: PropTypes.func
      }
      state = { data: [], loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT, pagination: {} }
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
          const { data, pagination, error } = await this.props.dispatcher({
            page: this.props.page,
            search: this.props.search,
            perPage: this.props.perPage,
            ...this.props
          })
          if (data) {
            this.setState({
              data,
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
          ...this.props,
          data: this.state.data,
          loadingStatus: this.state.loadingStatus,
          pagination: this.state.pagination
        })
      }
    }
  )
