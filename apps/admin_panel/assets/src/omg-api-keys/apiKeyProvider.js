import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'

import { selectKey } from './selector'
import { selectWalletByKeyId } from '../omg-wallet/selector'
import { getKeyById } from './action'

class ApiKeyProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    keyId: PropTypes.string,
    key: PropTypes.object,
    getKeyById: PropTypes.func,
  }

  // admin keys are access keys
  // client keys are api keys

  componentDidMount = () => {
    if (!this.props.key) {
      this.props.getKeyById(this.props.userId)
    }
  }
  render () {
    return this.props.render({
      user: this.props.user,
      wallet: this.props.wallet
    })
  }
}
export default connect(
  (state, props) => {
    return {
      key: selectKey(props.keyId)(state),
      wallet: selectWalletByKeyId(props.keyId)(state)
    }
  },
  { getKeyById }
)(ApiKeyProvider)
