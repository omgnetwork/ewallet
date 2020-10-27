import _ from 'lodash'

import { Component } from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import { compose } from 'recompose'
import { connect } from 'react-redux'

import { selectGetTokenById, selectTokenCapabilitiesById } from './selector'
import { getTokenById, getErc20Capabilities } from './action'

class TokenProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    tokenId: PropTypes.string,
    getTokenById: PropTypes.func.isRequired,
    selectTokenById: PropTypes.func,
    getErc20Capabilities: PropTypes.func,
    selectTokenCapabilitiesById: PropTypes.func
  }
  componentDidMount = async () => {
    const result = await this.props.getTokenById(this.props.tokenId)
    const blockchainAddress = _.get(result, 'data.token.blockchain_address')
    if (blockchainAddress) {
      this.props.getErc20Capabilities(blockchainAddress)
    }
  }
  render () {
    return this.props.render({
      token: this.props.selectTokenById(this.props.tokenId),
      blockchainBalance: this.props.selectTokenCapabilitiesById(this.props.tokenId)
    })
  }
}

const enhance = compose(
  withRouter,
  connect(
    state => {
      return {
        selectTokenById: selectGetTokenById(state),
        selectTokenCapabilitiesById: selectTokenCapabilitiesById(state)
      }
    },
    { getTokenById, getErc20Capabilities }
  )
)

export default enhance(TokenProvider)
