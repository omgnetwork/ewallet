import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import { Icon } from '../omg-uikit'
import Uploader from './Uploader'
const ImageUpload = styled.div`
  height: ${props => props.size ? props.size : '100px'};
  width: ${props => props.size ? props.size : '100px'};
  background-color: ${props => props.theme.colors.S200};
  background-image: url(${props => props.placeholder});
  background-size: cover;
  background-position: center;
  border-radius: 4px;
  border: 1px solid ${props => props.theme.colors.S200};
  margin: 50px auto 0 auto;
  color: white;
  position: relative;
  cursor: pointer;
  > * {
    pointer-events: ${props => (props.dragState === 'DRAG_ENTER' ? 'none' : 'inherit')};
  }
  i {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    left: 0;
    right: 0;
    margin: 0 auto;
    font-size: 25px;
    color: ${props => props =>
      props.dragState === 'DRAG_ENTER' ? props.theme.colors.S100 : props.theme.colors.S400};
  }
`
const OverlayContainer = styled.div`
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  bottom: 0;
`
const OverlayUpload = styled.div`
  width: 100%;
  height: 100%;
  background-color: ${props => props.theme.colors.B100};
  opacity: 0.5;
`

export default class ImageUploader extends Component {
  static propTypes = {
    onChangeImage: PropTypes.func,
    size: PropTypes.string,
    className: PropTypes.string,
    placeholder: PropTypes.string
  }
  renderOverlayUpload = () => {
    return (
      <OverlayContainer>
        <OverlayUpload />
        <Icon name='Upload' />
      </OverlayContainer>
    )
  }

  renderImageUpload = ({ image, dragState, path }, handleBrowseImage) => {
    return (
      <ImageUpload
        placeholder={path || this.props.placeholder}
        dragState={dragState}
        onClick={handleBrowseImage}
        size={this.props.size}
        className={this.props.className}
      >
        {dragState === 'DRAG_ENTER' && dragState !== 'DROP' ? (
          this.renderOverlayUpload()
        ) : (image || this.props.placeholder) ? null : (
          <Icon name='Camera' />
        )}
      </ImageUpload>
    )
  }

  render () {
    return <Uploader render={this.renderImageUpload} onChangeImage={this.props.onChangeImage} />
  }
}
