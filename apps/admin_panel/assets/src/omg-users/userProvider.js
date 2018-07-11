import { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { selectUser } from './selector'
import { selectWalletByUserId } from '../omg-wallet/selector'
import { getUserById } from './action'
import { getWalletsByUserId } from '../omg-wallet/action'
class UserProvider extends Component {
  static propTypes = {
    render: PropTypes.func,
    userId: PropTypes.string,
    user: PropTypes.object,
    wallet: PropTypes.object,
    getUserById: PropTypes.func,
    getWalletsByUserId: PropTypes.func
  }

  componentDidMount = () => {
    if (!this.props.user) {
      this.props.getUserById(this.props.userId)
    }
    this.props.getWalletsByUserId({ userId: this.props.userId, perPage: 1000 })
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
      user: selectUser(props.userId)(state),
      wallet: selectWalletByUserId(props.userId)(state)
    }
  },
  { getUserById, getWalletsByUserId }
)(UserProvider)
