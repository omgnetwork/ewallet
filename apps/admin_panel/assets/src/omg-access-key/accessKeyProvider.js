import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

import { selectUser } from './selector'
import { getAccessKey } from './action'

class AccessKeyProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    accessKeyId: PropTypes.string,
    accessKey: PropTypes.object,
    getAccessKey: PropTypes.func
  }

  componentDidMount = () => {
    if (!this.props.accessKey) {
      this.props.getAccessKey(this.props.accessKeyId)
    }
  }
  render () {
    return this.props.render({
      accessKey: this.props.accessKey
    })
  }
}
export default connect(
  (state, props) => {
    return {
      accessKey: selectUser(props.accessKeyId)(state)
    }
  },
  { getAccessKey }
)(AccessKeyProvider)
