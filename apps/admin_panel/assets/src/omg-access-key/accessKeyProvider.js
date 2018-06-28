import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectAccessKeys, selectAccessKeysLoadingStatus } from './selector'
import { getAccessKeys } from './action'
import { withRouter } from 'react-router-dom'
import { compose } from 'recompose'

const enhance = compose(
  withRouter,
  connect(
    state => {
      return {
        data: selectAccessKeys(state),
        loadingStatus: selectAccessKeysLoadingStatus(state)
      }
    },
    { getAccessKeys }
  )
)
class AccessKeyProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    data: PropTypes.array.isRequired,
    getAccessKeys: PropTypes.func.isRequired,
    loadingStatus: PropTypes.string
  }
  componentDidMount = () => {
    this.props.getAccessKeys()
  }
  render () {
    return this.props.render({
      data: this.props.data,
      loadingStatus: this.props.loadingStatus
    })
  }
}
export default enhance(AccessKeyProvider)
