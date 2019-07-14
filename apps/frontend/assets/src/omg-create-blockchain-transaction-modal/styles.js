import styled from 'styled-components'
import { Icon, Input, SelectInput } from '../omg-uikit'
export const Form = styled.div`
  width: 100vw;
  height: 100vh;
  position: relative;
  > i {
    position: absolute;
    right: 30px;
    top: 30px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
    font-size: 30px;
  }
  input {
    margin-top: 5px;
  }
  button {
    margin: 35px 0 0;
    font-size: 14px;
  }
  h4 {
    font-size: 18px;
  }
`
export const Title = styled.div`
  margin-bottom: 20px;
`
export const PendingIcon = styled(Icon)`
  color: white;
  background-color: orange;
  width: 30px;
  height: 30px;
  margin-bottom: 20px;
  display: flex;
  justify-content: center;
  align-items: center;
  border-radius: 100%;
`
export const ButtonContainer = styled.div`
  display: flex;
  flex-direction: row;
  justify-content: space-between;
`
export const Error = styled.div`
  color: ${props => props.theme.colors.R400};
  text-align: center;
  padding: 10px 0;
  overflow: hidden;
  max-height: ${props => (props.error ? '100px' : 0)};
  opacity: ${props => (props.error ? 1 : 0)};
  transition: 0.5s ease max-height, 0.3s ease opacity;
`
export const FromToContainer = styled.div`
  h5 {
    letter-spacing: 1px;
    background-color: ${props => props.theme.colors.S300};
    display: inline-block;
    padding: 5px 10px;
    border-radius: 2px;
  }
`
export const InnerTransferContainer = styled.div`
  max-width: 600px;
  padding: 50px;
  margin: 0 auto;
`
export const StyledSelectInput = styled(SelectInput)`
  margin-bottom: 10px;
`
export const StyledInput = styled(Input)`
  margin-bottom: 20px;
`
export const PasswordInput = styled(Input)`
  margin-top: 40px;
`
export const Label = styled.div`
  color: ${props => props.theme.colors.S400};
`
export const Collapsable = styled.div`
  background-color: ${props => props.theme.colors.S100};
  text-align: left;
  border-radius: 6px;
  border: 1px solid ${props => props.theme.colors.S400};
  margin-top: 20px;
`
export const FeeContainer = styled.div`
  padding: 10px;
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  border-radius: 6px;
  i[name='Info'] {
    color: ${props => props.theme.colors.S400};
    margin-left: 5px;
    cursor: pointer;
  }
`
export const GrayFeeContainer = styled(FeeContainer)`
  background-color: ${props => props.theme.colors.S200};
`
export const CollapsableHeader = styled.div`
  cursor: pointer;
  padding: 10px 20px;
  display: flex;
  align-items: center;
  color: ${props => props.theme.colors.S500};
  > i {
    margin-left: auto;
  }
`
export const CollapsableContent = styled.div`
  padding: 40px;
  border-radius: 6px;
  background-color: white;
  display: flex;
  flex-direction: column;
  height: 100%;
`
export const Links = styled.div`
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  justify-content: flex-end;
  color: ${props => props.theme.colors.B100};
  span {
    margin-top: 5px;
    cursor: pointer;
  }
  i[name='Arrow-Right'] {
    margin-left: 5px;
  }
`
