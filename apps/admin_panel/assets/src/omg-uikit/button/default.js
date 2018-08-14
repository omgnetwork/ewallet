import styled from 'styled-components'
const mapSize = {
  small: '8px 15px',
  medium: '10px 15px',
  large: '12px 15px'
}
export const DefaultButton = styled.button`
  color: white;
  border-radius: 4px;
  border: 1px solid transparent;
  padding: ${props => mapSize[props.size || 'medium']};
  width: ${props => props.fluid ? '100%' : 'auto'};
  position: relative;
  pointer-events: ${props => props.loading ? 'none' : 'auto'};
  cursor: pointer;
  .loading {
    opacity: ${props => props.loading ? 1 : 0};
    margin: 0 auto;
    position: absolute;
    left: 0;
    right: 0;
    top: 50%;
    height: 20px;
    transform: translateY(-50%);
  }
`
export const Content = styled.div`
  opacity: ${props => (props.loading ? 0 : 1)};
`
