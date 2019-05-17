import { Component } from 'react'
import { withRouter } from 'react-router-dom'
import PropTypes from 'prop-types'
import { compose } from 'recompose'
import { connect } from 'react-redux'

import { selectGetTokenById } from './selector'
import { getTokenById } from './action'

const enhance = compose(
  withRouter,
  connect(
    state => {
      return {
        selectTokenById: selectGetTokenById(state)
      }
    },
    { getTokenById }
  )
)
class TokenProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    tokenId: PropTypes.string,
    getTokenById: PropTypes.func.isRequired,
    selectTokenById: PropTypes.func
  }
  componentDidMount = () => {
    this.props.getTokenById(this.props.tokenId)
  }
  render () {
    return this.props.render({
      token: this.props.selectTokenById(this.props.tokenId)
    })
  }
}
export default enhance(TokenProvider)
