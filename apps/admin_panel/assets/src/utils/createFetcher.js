import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { withProps, compose } from 'recompose'
import CONSTANT from '../constants'
import { selectCacheQueriesByEntity } from '../omg-cache/selector'
export const createCacheKey = (props, entity) => JSON.stringify({ ...props.query, entity })
export const createFetcher = (entity, reducer, selectors) => {
  const enhance = compose(
    withProps(props => ({ cacheKey: createCacheKey(props, entity) })),
    connect(
      (state, props) => {
        return {
          ...selectors(state, props),
          queriesByEntity: selectCacheQueriesByEntity(entity)(state)
        }
      },
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
        pagination: PropTypes.object,
        queriesByEntity: PropTypes.array
      }
      static defaultProps = {
        onFetchComplete: _.noop
      }

      static getDerivedStateFromProps (props, state) {
        const intersec = _.intersectionBy(props.data, state.data, d => d.id)
        if (intersec.length && state.loadingStatus === CONSTANT.LOADING_STATUS.SUCCESS) {
          return { data: props.data, pagination: props.pagination }
        }
        return null
      }
      state = {
        loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT,
        data: this.props.data,
        pagination: this.props.pagination
      }

      constructor (props) {
        super(props)
        this.fetched = {}
        this.fetchDebounce = _.debounce(this.fetch, 300, {
          leading: true,
          trailing: true
        })
      }
      componentDidMount = () => {
        this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.INITIATED })
        this.fetch()
      }
      componentDidUpdate = async nextProps => {
        if (this.props.cacheKey !== nextProps.cacheKey) {
          this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.PENDING })
          await this.fetchDebounce()
        }
      }
      getQuery = () => {
        return { page: 1, perPage: 10, ...this.props.query }
      }
      fetch = async () => {
        try {
          this.setState(oldState => ({
            loadingStatus:
              oldState.loadingStatus === CONSTANT.LOADING_STATUS.INITIATED
                ? CONSTANT.LOADING_STATUS.INITIATED
                : CONSTANT.LOADING_STATUS.PENDING
          }))
          this.props.dispatcher({ ...this.props, ...this.getQuery() }).then(result => {
            this.fetched[this.props.cacheKey] = true
            if (result.data) {
              this.setState({
                loadingStatus: CONSTANT.LOADING_STATUS.SUCCESS,
                data: this.props.data,
                pagination: this.props.pagination
              })
              this.props.onFetchComplete()
            } else {
              this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.FAILED })
            }
          })
        } catch (error) {
          this.setState({
            loadingStatus: CONSTANT.LOADING_STATUS.FAILED,
            data: this.props.data,
            pagination: this.props.pagination
          })
        }
      }

      render () {
        return this.props.render({
          ...this.props,
          ...this.getQuery(),
          individualLoadingStatus: this.state.loadingStatus,
          fetch: this.fetch,
          data:
            this.state.loadingStatus === CONSTANT.LOADING_STATUS.SUCCESS
              ? this.props.data
              : this.state.data,
          pagination:
            this.state.loadingStatus === CONSTANT.LOADING_STATUS.SUCCESS
              ? this.props.pagination
              : this.state.pagination
        })
      }
    }
  )
}
