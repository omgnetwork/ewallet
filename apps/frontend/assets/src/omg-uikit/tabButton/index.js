import styled from 'styled-components'

const TabButton = styled.button`
  padding: 5px 10px;
  border-radius: 4px;
  background-color: ${({ active, theme }) =>
    active ? theme.colors.S200 : 'white'};
  color: ${({ active, theme }) =>
    active ? theme.colors.B500 : theme.colors.B100};
  margin-right: 10px;
  border: 1px solid transparent;
  min-width: 100px;
  :hover {
    border: 1px solid ${props => props.theme.colors.S300};
  }
`

export default TabButton
