import styled from 'styled-components'
import { DefaultButton } from './default'

export const DangerPrimary = styled(DefaultButton)`
  background-color: ${props => (props.loading ? props.theme.colors.R300 : props.theme.colors.R300)};
  :hover {
    background-color: ${props => (props.loading ? props.theme.colors.R300 : props.theme.colors.R200)};
  }
  :active {
    background-color: ${props => (props.loading ? props.theme.colors.R300 : props.theme.colors.R300)};
  }
`

export const ButtonDisabled = styled(DefaultButton)`
  color: white;
  background-color: ${props => props.theme.colors.S500};
  cursor: initial;
`
