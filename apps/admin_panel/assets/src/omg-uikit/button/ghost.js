import styled from 'styled-components'
import { DefaultButton } from './default'

export const ButtonGhost = styled(DefaultButton)`
  background-color: transparent;
  color: ${props => (props.loading ? props.theme.colors.B300 : props.theme.colors.B300)};
  border-color : ${props => (props.loading ? props.theme.colors.S200 : props.theme.colors.S400)};
  :hover {
    border-color: ${props => (props.loading ? props.theme.colors.S300 : props.theme.colors.S300)};
    background-color: ${props => (props.loading ? props.theme.colors.S200 : props.theme.colors.S200)};
  }
  :active {
    border-color: ${props => (props.loading ? props.theme.colors.S400 : props.theme.colors.S400)};
    background-color: ${props => (props.loading ? props.theme.colors.B100 : props.theme.colors.S300)};
  }
`
