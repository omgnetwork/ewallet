import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectApiKeys, selectApiKeysLoadingStatus } from './selector'
import { loadApiKeys } from './action'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'

const enhance = compose(
  withRouter,
  connect(
    state => {
      return {
        apiKeys: selectApiKeys(state),
        apiKeysLoadingStatus: selectApiKeysLoadingStatus(state)
      }
    },
    { loadApiKeys }
  )
)
class ApiKeyProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    apiKeys: PropTypes.array.isRequired,
    loadApiKeys: PropTypes.func.isRequired,
    apiKeysLoadingStatus: PropTypes.string
  }
  componentDidMount = () => {
    if (this.props.apiKeysLoadingStatus === 'DEFAULT') {
      this.props.loadApiKeys()
    }
  }
  render () {
    return this.props.render({
      apiKeys: this.props.apiKeys,
      loadingStatus: this.props.apiKeysLoadingStatus
    })
  }
}
export default enhance(ApiKeyProvider)
