import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectExchangePairsByFromTokenId } from './selector'
import { getExchangePairs } from './action'
class ExchangePairProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    fromTokenId: PropTypes.string,
    exchangePairs: PropTypes.object,
    getExchangePairs: PropTypes.func
  }
  componentDidMount = () => {
    this.props.getExchangePairs({ searchTerms: { from_token_id: this.props.fromTokenId } })
  }
  render () {
    return this.props.render({ exchangePairs: this.props.exchangePairs })
  }
}
export default connect(
  (state, props) => {
    return {
      exchangePairs: selectExchangePairsByFromTokenId(state)(props.fromTokenId)
    }
  },
  { getExchangePairs }
)(ExchangePairProvider)
