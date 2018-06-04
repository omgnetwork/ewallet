import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectTokens, selectTokensLoadingStatus } from './selector'
import { loadTokens } from './action'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'

const enhance = compose(
  withRouter,
  connect(
    (state, props) => {
      return {
        tokens: selectTokens(state, props.search),
        tokensLoadingStatus: selectTokensLoadingStatus(state)
      }
    },
    { loadTokens }
  )
)
class TokensProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    tokens: PropTypes.array.isRequired,
    loadTokens: PropTypes.func.isRequired,
    tokensLoadingStatus: PropTypes.string,
    search: PropTypes.string
  }
  componentWillReceiveProps = nextProps => {
    if (this.props.search !== nextProps.search) {
      this.props.loadTokens(nextProps.search)
    }
  }

  componentDidMount = () => {
    if (this.props.tokensLoadingStatus === 'DEFAULT') {
      this.props.loadTokens()
    }
  }
  render () {
    return this.props.render({
      tokens: this.props.tokens,
      loadingStatus: this.props.tokensLoadingStatus
    })
  }
}
export default enhance(TokensProvider)
