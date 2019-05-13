import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { Avatar } from '../omg-uikit'
import styled from 'styled-components'

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
    token: PropTypes.object
  }
  static defaultProps = {
    wallet: {}
  }

  render () {
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
        </DetailContainer>
      </TokenSelectItemContainer>
    )
  }
}
