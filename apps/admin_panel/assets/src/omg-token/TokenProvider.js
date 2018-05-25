import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectGetTokenById, selectTokensLoadingStatus } from './selector'
import { loadTokens } from './action'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'

const enhance = compose(
  withRouter,
  connect(
    state => {
      return {
        selectTokenById: selectGetTokenById(state),
        tokensLoadingStatus: selectTokensLoadingStatus(state)
      }
    },
    { loadTokens }
  )
)
class TokensProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    tokenId: PropTypes.string,
    loadTokens: PropTypes.func.isRequired,
    tokensLoadingStatus: PropTypes.string,
    selectTokenById: PropTypes.func
  }
  componentDidMount = () => {
    if (this.props.tokensLoadingStatus === 'DEFAULT') {
      this.props.loadTokens()
    }
  }
  render () {
    return this.props.render({
      token: this.props.selectTokenById(this.props.tokenId),
      loadingStatus: this.props.tokensLoadingStatus
    })
  }
}
export default enhance(TokensProvider)
