import React, { Component } from 'react'
import PropTypes from 'prop-types'
import ReactDom from 'react-dom'

class ImageUploader extends Component {
  static propTypes = {
    render: PropTypes.func.isRequired,
    onChangeImage: PropTypes.func
  }
  static defaultProps = {}
  constructor (props) {
    super(props)
    this.accept = 'image/jpeg, image/png, image/jpg, image/gif'
    this.state = {
      file: null,
      dragState: null
    }
  }
  componentDidMount = () => {
    this.fileInputDom = ReactDom.findDOMNode(this.fileInput)
  }

  handleBrowseImage = e => {
    this.fileInputDom.click()
  }

  handleDrop = e => {
    e.preventDefault()
    const file = e.dataTransfer.files[0]
    if (this.accept.indexOf(file.type) === -1) return
    if (this.state.dragState !== 'DROP') {
      this.setState({ dragState: 'DROP' })
    }
    this.readFile(file)
  }

  handleDragEnter = e => {
    e.preventDefault()
    if (this.state.dragState !== 'DRAG_ENTER') {
      this.setState({ dragState: 'DRAG_ENTER' })
    }
  }

  handleDragLeave = e => {
    e.preventDefault()
    e.stopPropagation()
    if (this.state.dragState !== 'DRAG_LEAVE') {
      this.setState({ dragState: 'DRAG_LEAVE' })
    }
  }

  handleChangeImage = e => {
    const file = e.target.files[0]
    this.readFile(file)
  }

  readFile = file => {
    const reader = new window.FileReader()
    reader.onloadend = () => {
      const state = { file, image: reader.result, path: window.URL.createObjectURL(file) }
      this.props.onChangeImage(state)
      this.setState(state)
    }
    reader.readAsDataURL(file)
  }

  handleRemoveImg = () => {
    this.fileInputDom.value = null
    this.setState({ file: null })
  }
  render () {
    return (
      <div
        onDragEnter={e => e.preventDefault()}
        onDragLeave={this.handleDragLeave}
        onDragOver={this.handleDragEnter}
        onDrop={this.handleDrop}
      >
        {this.props.render(this.state, this.handleBrowseImage)}
        <input
          accept={this.accept}
          ref={input => (this.fileInput = input)}
          onChange={this.handleChangeImage}
          style={{ display: 'none' }}
          type='file'
        />
      </div>
    )
  }
}

export default ImageUploader

