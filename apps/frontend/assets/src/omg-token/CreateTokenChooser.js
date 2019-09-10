import React, { Component } from 'react'
import { connect } from 'react-redux'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { compose } from 'recompose'

import PopperRenderer from '../omg-popper'
import { openModal } from '../omg-modal/action'
import withDropdownState from '../omg-uikit/dropdown/withDropdownState'
import { Icon, Button } from '../omg-uikit'
import { DropdownBox } from '../omg-uikit/dropdown'

const DropdownItem = styled.div`
  padding: 7px 10px;
  padding-right: 20px;
  font-size: 12px;
  color: ${props => props.theme.colors.B100};
  cursor: pointer;
  i,
  span {
    vertical-align: middle;
    display: inline-block;
  }
  :hover {
    color: ${props => props.theme.colors.B400};
  }
  i {
    margin-right: 5px;
  }
`
const ButtonStyle = styled(Button)`
  margin-left: 10px;
  i {
    margin-left: 10px;
    margin-right: 0 !important;
  }
`
class CreateTokenChooser extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onClickButton: PropTypes.func,
    openModal: PropTypes.func,
    refetch: PropTypes.func
  }
  renderDropdown = () => {
    return (
      <DropdownBox>
        <DropdownItem
          key='internal-token'
          onClick={() => {
            this.props.openModal({
              id: 'createTokenModal',
              refetch: this.props.refetch
            })
          }}
        >
          <Icon name='Token' />
          <span>Create Internal Token</span>
        </DropdownItem>
        <DropdownItem
          key='import-token'
          onClick={() => this.props.openModal({
            id: 'importTokenModal',
            refetch: this.props.refetch
          })}
        >
          <Icon name='Download' />
          <span>Import Blockchain Token</span>
        </DropdownItem>
      </DropdownBox>
    )
  }
  renderButton = () => {
    return (
      <ButtonStyle
        key='create-token-chooser'
        size='small'
        styleType='primary'
        onClick={this.props.onClickButton}
      >
        <span>Create Token</span>
        {this.props.open
          ? <Icon name='Chevron-Up' />
          : <Icon name='Chevron-Down' />
        }
      </ButtonStyle>
    )
  }
  render () {
    return (
      <PopperRenderer
        offset='0px, 5px'
        modifiers={{ flip: { enabled: false } }}
        renderReference={this.renderButton}
        open={this.props.open}
        renderPopper={this.renderDropdown}
      />
    )
  }
}

const enhance = compose(
  withDropdownState,
  connect(
    null,
    { openModal }
  )
)

export default enhance(CreateTokenChooser)
