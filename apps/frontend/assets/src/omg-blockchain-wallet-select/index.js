import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Icon, Id } from '../omg-uikit'

const WalletSelectItemContainer = styled.div`
  display: flex;
  flex-direction: row;
  align-items: center;
`
const DetailContainer = styled.div`
  display: inline-block;
  vertical-align: middle;
`
const WalletNameAndIdentifier = styled.div`
  color: ${props => props.theme.colors.B100};
  font-size: 10px;
`
const StyledIcon = styled.div`
  color: ${props => props.theme.colors.B100};
  border-radius: 4px;
`
export default class BlockchainWalletSelect extends Component {
  static propTypes = {
    icon: PropTypes.string,
    topRow: PropTypes.string,
    bottomRow: PropTypes.string
  }
  render () {
    return (
      <WalletSelectItemContainer>
        <StyledIcon>
          <Icon name={this.props.icon} />
        </StyledIcon>
        <DetailContainer>
          {this.props.topRow}
          <WalletNameAndIdentifier>
            {this.props.bottomRow}
          </WalletNameAndIdentifier>
        </DetailContainer>
      </WalletSelectItemContainer>
    )
  }
}
