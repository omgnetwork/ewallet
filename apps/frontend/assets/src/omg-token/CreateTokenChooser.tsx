import React, { FunctionComponent } from 'react'
import { useSelector, useDispatch } from 'react-redux'
import styled from 'styled-components'
import { compose } from 'recompose'

import PopperRenderer from 'omg-popper'
import { openModal } from 'omg-modal/action'
import withDropdownState from 'omg-uikit/dropdown/withDropdownState'
import { Icon, Button } from 'omg-uikit'
import { DropdownBox } from 'omg-uikit/dropdown'
import { selectBlockchainEnabled } from 'omg-configuration/selector'

const DropdownItemContainer = styled.div`
  padding: 7px 20px 7px 10px;
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
interface CreateTokenChooserProps {
    open: boolean,
    onClickButton: Function,
    refetch: Function,
}

interface DropdownItemProps {
  icon: string,
  text: string,
  onClick: () => void
}

const DropdownItem = ({icon, text, onClick }:DropdownItemProps) => {
  return (
    <DropdownItemContainer onClick={onClick} >
      <Icon name={icon} />
      <span>{text}</span>
    </DropdownItemContainer>)
}


const CreateTokenChooser: FunctionComponent<CreateTokenChooserProps> = ({onClickButton, open, refetch}:CreateTokenChooserProps) => {
  const blockchainEnabled: boolean = useSelector(selectBlockchainEnabled())

  const dispatch = useDispatch()
  const show = (id) => () => dispatch(openModal({id, refetch}))
  
  const renderDropdown = () => {
    return (
      <DropdownBox>
        {blockchainEnabled? null : <DropdownItem icon='Token' text='Create Internal Token' onClick={show('createTokenModal')}/>}
        <DropdownItem icon='Token' text='Create Blockchain Token' onClick={show('createBlockchainTokenModal')}/>
        <DropdownItem icon='Download' text='Import Blockchain Token' onClick={show('importTokenModal')}/>
      </DropdownBox>
    )
  }
  const renderButton = () => {
    return (
      <ButtonStyle
        key='create-token-chooser'
        size='small'
        styleType='primary'
        onClick={onClickButton}
      >
        <span>Create Token</span>
        {open
          ? <Icon name='Chevron-Up' />
          : <Icon name='Chevron-Down' />
        }
      </ButtonStyle>
    )
  }
  return (
    <PopperRenderer
      offset='0px, 5px'
      modifiers={{ flip: { enabled: false } }}
      renderReference={renderButton}
      open={open}
      renderPopper={renderDropdown}
    />
  )
}

const enhance = compose(withDropdownState)

export default enhance(CreateTokenChooser)
