import styled from 'styled-components'
import { DefaultButton } from './default'

export const ButtonPrimary = styled(DefaultButton)`
  background-color: ${props => (props.loading ? props.theme.colors.BL200 : props.theme.colors.BL400)};
  :hover {
    background-color: ${props => (props.loading ? props.theme.colors.BL200 : props.theme.colors.BL300)};
  }
  :active {
    background-color: ${props => (props.loading ? props.theme.colors.BL200 : props.theme.colors.BL500)};
  }
`
