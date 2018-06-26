import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { withProps, compose } from 'recompose'
import CONSTANT from '../constants'
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
      static defaultProps = {
        onFetchComplete: _.noop
      }
      state = { loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT }

      constructor (props) {
        super(props)
        this.fetchDebounce = _.debounce(this.fetch, 300, {
          'leading': true,
          'trailing': false
        })
      }
      componentDidMount = () => {
        this.fetch()
      }
      componentDidUpdate = async nextProps => {
        if (this.props.cacheKey !== nextProps.cacheKey) {
          await this.fetchDebounce()
        }
      }
      fetch = async () => {
        try {
          this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.INITIATED })
          const result = await this.props.dispatcher({ ...this.props, ...this.props.query })
          if (result.data) {
            this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.SUCCESS })
            this.props.onFetchComplete()
          } else {
            this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.FAILED })
          }
        } catch (error) {
          console.log(error)
          this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.FAILED })
        }
      }

      render () {
        return this.props.render({
          ...this.props,
          ...this.props.query,
          individualLoadingStatus: this.state.loadingStatus,
          fetch: this.fetch
        })
      }
    }
  )
}
