import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { withProps, compose } from 'recompose'
import CONSTANT from '../constants'
import { selectCacheQueriesByEntity } from '../omg-cache/selector'
export const createFetcher = (entity, reducer, selectors) => {
  const enhance = compose(
    withProps(props => ({ cacheKey: `${JSON.stringify({ ...props.query, entity })}` })),
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
        queriesByEntity: PropTypes.string
      }
      static defaultProps = {
        onFetchComplete: _.noop
      }
      state = { loadingStatus: CONSTANT.LOADING_STATUS.DEFAULT, data: [] }

      constructor (props) {
        super(props)
        this.fetchDebounce = _.debounce(this.fetch, 300, {
          leading: true,
          trailing: false
        })
      }
      static getDerivedStateFromProps (props, state) {
        const diff = _.differenceBy(props.data, state.data, d => d.id)
        if (diff.length > 0) {
          return { data: props.data }
        }
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
      fetchAll = async () => {
        try {
          const promises = this.props.queriesByEntity.map(query => {
            const { page } = JSON.parse(query)
            return this.props.dispatcher({
              ...this.props,
              ...this.props.query,
              page,
              cacheKey: `${JSON.stringify({ ...this.props.query, page, entity })}`
            })
          })
          Promise.all(promises)
        } catch (error) {
          console.log('cannot fetch all cache query with error', error)
        }
      }
      fetch = async () => {
        try {
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
        this.setState({ loadingStatus: CONSTANT.LOADING_STATUS.SUCCESS })
      }

      render () {
        return this.props.render({
          ...this.props,
          ...this.props.query,
          individualLoadingStatus: this.state.loadingStatus,
          fetch: this.fetch,
          fetchAll: this.fetchAll,
          data: this.state.data
        })
      }
    }
  )
}
