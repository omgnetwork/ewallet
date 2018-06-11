import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectCategories, selectCategoriesLoadingStatus } from './selector'
import { getCategories } from './action'
import { compose } from 'recompose'
const ehance = compose(
  connect(
    (state, props) => {
      return {
        categories: selectCategories(state, props.search),
        categoriesLoadingStatus: selectCategoriesLoadingStatus(state)
      }
    },
    { getCategories }
  )
)
class AccountsProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    categories: PropTypes.array,
    getCategories: PropTypes.func,
    categoriesLoadingStatus: PropTypes.string,
    search: PropTypes.string
  }
  componentWillReceiveProps = nextProps => {
    if (this.props.search !== nextProps.search) {
      this.props.getCategories(nextProps.search)
    }
  }

  componentDidMount = () => {
    if (this.props.categoriesLoadingStatus === 'DEFAULT') {
      this.props.getCategories()
    }
  }
  render () {
    return this.props.render({
      transactions: this.props.categories,
      loadingStatus: this.props.categoriesLoadingStatus
    })
  }
}
export default ehance(AccountsProvider)
