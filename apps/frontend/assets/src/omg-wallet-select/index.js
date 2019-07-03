import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Avatar } from '../omg-uikit'

const StyledAvatar = styled(Avatar)`
  display: inline-block;
  vertical-align: middle;
  margin-right: 10px;
`

const WalletSelectItemContainer = styled.div`
  position: relative;
  white-space: nowrap;
`
const DetailContainer = styled.div`
  display: inline-block;
  vertical-align: middle;
`
const Address = styled.div``
const WalletNameAndIdentifier = styled.div`
  color: ${props => props.theme.colors.B100};
  font-size: 10px;
`
export default class WalletSelectItem extends Component {
  static propTypes = {
    wallet: PropTypes.object
  }
  static defaultProps = {
    wallet: {}
  }
  getIdentifier (identifier) {
    switch (identifier) {
      case 'primary':
        return 'Primary'
      case 'burn':
        return 'Burn'
      default:
        return 'Secondary'
    }
  }
  render () {
    const accountName = _.get(this.props.wallet, 'account.name')
    const userName = _.get(this.props.wallet, 'user.username')
    const userEmail = _.get(this.props.wallet, 'user.email')
    const type = this.props.wallet.account ? 'account' : 'user'
    return (
      <WalletSelectItemContainer>
        <StyledAvatar
          image={_.get(this.props.wallet, 'account.avatar.thumb')}
          name={accountName || userName || userEmail || ''}
        />
        <DetailContainer>
          <Address>{this.props.wallet.address}</Address>
          <WalletNameAndIdentifier>
            {this.props.wallet.address.includes('gnis000')
              ? 'Genesis'
              : `${_.upperFirst(type)} ${accountName || userName || userEmail} | ${this.props.wallet.name} - ${this.getIdentifier(this.props.wallet.identifier)}`}
          </WalletNameAndIdentifier>
        </DetailContainer>
      </WalletSelectItemContainer>
    )
  }
}
