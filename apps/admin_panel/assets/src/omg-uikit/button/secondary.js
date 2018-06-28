import styled from 'styled-components'
import { DefaultButton } from './default'

export const ButtonSecondary = styled(DefaultButton)`
  color: ${props => (props.disabled ? props.theme.colors.S400 : props.theme.colors.BL400)};
  background-color: transparent;
  border-color: ${props => (props.disabled ? props.theme.colors.S400 : props.theme.colors.BL400)};
  pointer-events: ${props => props.disabled ? 'none' : 'auto'};
  :hover {
    background-color: ${props => props.theme.colors.S100};
  }
`
