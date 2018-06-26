import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import CONSTANT from '../constants'
import { withProps, compose } from 'recompose'
export const createFetcher = (reducer, selectors) => {
  const enhance = compose(
    withProps(props => ({ cacheKey: JSON.stringify(props.query) })),
    connect(
      selectors,
      { dispatcher: reducer }
    )
  )
  return enhance(
    class Fetcher extends Component {
      static propTypes = {
        render: PropTypes.func,
        search: PropTypes.string,
        page: PropTypes.number,
        perPage: PropTypes.number,
        onFetchComplete: PropTypes.func,
        loadingStatus: PropTypes.string,
        cacheKey: PropTypes.string,
        data: PropTypes.array,
        pagination: PropTypes.object,
        query: PropTypes.object
      }
      componentDidMount = () => {
        this.fetch()
      }
      componentDidUpdate = nextProps => {
        if (this.props.cacheKey !== nextProps.cacheKey) {
          this.fetch()
        }
      }
      fetch = async () => {
        this.props.dispatcher({ ...this.props.query, cacheKey: this.props.cacheKey })
      }

      render () {
        return this.props.render({
          ...this.props.query,
          data: this.props.data,
          loadingStatus: this.props.loadingStatus,
          pagination: this.props.pagination,
          fetch: this.fetch
        })
      }
    }
  )
}
