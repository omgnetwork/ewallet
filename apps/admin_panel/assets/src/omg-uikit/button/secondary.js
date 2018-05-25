import styled from 'styled-components'
import { DefaultButton } from './default'

export const ButtonSecondary = styled(DefaultButton)`
  background-color: transparent;
  color:${props => props.theme.colors.BL400};
  border-color: ${props => props.theme.colors.BL400};
  :hover {
    background-color: ${props => props.theme.colors.S200};
  }
`
