import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

import { selectGetApiKeyById } from './selector'
import { getApiKey } from './action'

// aka frontend ui -> "Client Keys"
class ApiKeyProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    apiKeyId: PropTypes.string,
    apiKey: PropTypes.object,
    getApiKey: PropTypes.func
  }

  componentDidMount = () => {
    if (!this.props.apiKey) {
      this.props.getApiKey(this.props.apiKeyId)
    }
  }
  render () {
    return this.props.render({
      keyDetail: this.props.apiKey
    })
  }
}
export default connect(
  (state, props) => {
    return {
      apiKey: selectGetApiKeyById(state)(props.apiKeyId)
    }
  },
  { getApiKey }
)(ApiKeyProvider)
