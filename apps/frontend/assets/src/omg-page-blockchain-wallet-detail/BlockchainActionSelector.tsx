import React from 'react'
import { useDispatch } from 'react-redux'
import styled from 'styled-components'

import PopperRenderer from 'omg-popper'
import withDropdownState from 'omg-uikit/dropdown/withDropdownState'
import { openModal } from 'omg-modal/action'
import { Icon, Button } from 'omg-uikit'
import { DropdownBox } from 'omg-uikit/dropdown'

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

interface BlockchainActionSelectorProps {
  name: string
  onClickButton: React.MouseEventHandler
  open: boolean
  actions: Array<{
    name: string
    modal: { id: string; args: {} }
    icon: string
  }>
  fromAddress: string
}

const BlockchainActionSelector = ({
  name,
  actions,
  open,
  onClickButton,
  fromAddress
}: BlockchainActionSelectorProps) => {
  const dispatch = useDispatch()

  const renderDropdown = () => {
    return (
      <DropdownBox>
        {actions.map((action, index) => {
          const onClick = () =>
            dispatch(
              openModal({
                id: action.modal.id,
                fromAddress,
                ...action.modal.args
              })
            )
          return (
            <DropdownItem key={index} onClick={onClick}>
              <Icon name={action.icon} />
              <span>{action.name}</span>
            </DropdownItem>
          )
        })}
      </DropdownBox>
    )
  }

  const renderButton = () => {
    return (
      <ButtonStyle size="small" styleType="primary" onClick={onClickButton}>
        <span>{name}</span>
        {open ? <Icon name="Chevron-Up" /> : <Icon name="Chevron-Down" />}
      </ButtonStyle>
    )
  }

  return (
    <PopperRenderer
      offset="0px, 5px"
      modifiers={{
        flip: { enabled: false },
        preventOverflow: { enabled: false }
      }}
      renderReference={renderButton}
      open={open}
      renderPopper={renderDropdown}
    />
  )
}

export default withDropdownState(BlockchainActionSelector)
