import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

import { selectGetApiKeyById } from './selector'
import { getApiKey, updateApiKey, enableApiKey } from './action'

// aka frontend ui -> "Client Keys"
class ApiKeyProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    apiKeyId: PropTypes.string,
    apiKey: PropTypes.object,
    getApiKey: PropTypes.func,
    updateApiKey: PropTypes.func,
    enableApiKey: PropTypes.func
  }

  componentDidMount = () => {
    if (!this.props.apiKey) {
      this.props.getApiKey(this.props.apiKeyId)
    }
  }

  render () {
    return this.props.render({
      keyDetail: this.props.apiKey,
      updateKey: name => this.props.updateApiKey({ id: this.props.apiKeyId, name }),
      enableKey: enabled => this.props.enableApiKey({ id: this.props.apiKeyId, enabled })
    })
  }
}

export default connect(
  (state, props) => {
    return {
      apiKey: selectGetApiKeyById(state)(props.apiKeyId)
    }
  },
  { getApiKey, updateApiKey, enableApiKey }
)(ApiKeyProvider)
