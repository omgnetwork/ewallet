import React, { Component } from 'react'
import styled from 'styled-components'
import PropTypes from 'prop-types'
import { formatReceiveAmountToTotal } from '../utils/formatter'

import { Avatar } from '../omg-uikit'

const StyledAvatar = styled(Avatar)`
  display: inline-block;
  vertical-align: middle;
  margin-right: 10px;
`

const TokenSelectItemContainer = styled.div`
  position: relative;
  white-space: nowrap;
`
const DetailContainer = styled.div`
  display: inline-block;
  vertical-align: middle;
`
const Address = styled.div``
const TokenNameAndIdentifier = styled.div`
  color: ${props => props.theme.colors.B100};
  font-size: 10px;
`
export default class WalletSelectItem extends Component {
  static propTypes = {
    token: PropTypes.object,
    balance: PropTypes.number
  }
  static defaultProps = {
    wallet: {}
  }

  render () {
    const amount = formatReceiveAmountToTotal(
      this.props.balance,
      _.get(this.props.token, 'subunit_to_unit')
    )
    const name = _.get(this.props.token, 'name')
    const symbol = _.get(this.props.token, 'symbol')
    return (
      <TokenSelectItemContainer>
        <StyledAvatar
          name={name}
        />
        <DetailContainer>
          <Address>{name}</Address>
          <TokenNameAndIdentifier>
            {symbol}
          </TokenNameAndIdentifier>
          <TokenNameAndIdentifier>
            {amount}
          </TokenNameAndIdentifier>
        </DetailContainer>
      </TokenSelectItemContainer>
    )
  }
}
