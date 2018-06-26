import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { withProps, compose } from 'recompose'
export const createFetcher = (entity, reducer, selectors) => {
  const enhance = compose(
    withProps(props => ({ cacheKey: `${entity}:${JSON.stringify(props.query)}` })),
    connect(
      selectors,
      { dispatcher: reducer }
    )
  )
  return enhance(
    class Fetcher extends Component {
      static propTypes = {
        render: PropTypes.func,
        query: PropTypes.shape({
          page: PropTypes.number,
          perPage: PropTypes.number,
          search: PropTypes.string
        }),
        onFetchComplete: PropTypes.func,
        loadingStatus: PropTypes.string,
        cacheKey: PropTypes.string,
        data: PropTypes.array,
        pagination: PropTypes.object
      }
      componentDidMount = () => {
        this.fetch()
      }
      componentDidUpdate = async nextProps => {
        if (this.props.cacheKey !== nextProps.cacheKey) {
          await this.fetch()
          this.props.onFetchComplete()
        }
      }
      fetch = async () => {
        this.props.dispatcher({ ...this.props, ...this.props.query })
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
