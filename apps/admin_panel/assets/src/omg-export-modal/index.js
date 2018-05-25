import React, { Component } from 'react'
import PropTypes from 'prop-types'
import styled from 'styled-components'
import Modal from 'react-modal'
import { Icon, RadioButton, Button, Checkbox } from '../omg-uikit'
const customStyles = {
  content: {
    top: '50%',
    left: '50%',
    right: 'auto',
    bottom: 'auto',
    marginRight: '-50%',
    transform: 'translate(-50%, -50%)',
    border: 'none',
    padding: 0
  },
  overlay: {
    backgroundColor: 'rgba(0,0,0,0.5)'
  }
}
const ExportContainer = styled.div`
  padding: 50px;
  position: relative;
  width: 320px;
  text-align: center;
  > i {
    position: absolute;
    right: 15px;
    top: 15px;
    color: ${props => props.theme.colors.S400};
    cursor: pointer;
  }
  > h4 {
    margin-bottom: 20px;
    text-align: center;
  }
`
const ExportButton = styled(Button)`
  margin: 30px auto 0 auto;
`
const RadioButtonsCointaner = styled.div`
  text-align: left;
  > div:not(:last-child) {
    margin-bottom: 10px;
  }
  padding-bottom: 20px;
  border-bottom: 1px solid ${props => props.theme.colors.S400};
`
const FormatHeader = styled.div`
  margin: 20px 0;
`
const FormatExportContainer = styled.div`
  text-align: left;
  > div:not(${FormatHeader}) {
    margin-bottom: 15px;
  }
`

class ExportModal extends Component {
  static propTypes = {
    open: PropTypes.bool,
    onRequestClose: PropTypes.func
  }
  state = {
    exportType: 'current'
  }
  onClickRadioButton = exportType => e => {
    this.setState({exportType})
  }

  render () {
    return (
      <Modal
        isOpen={this.props.open}
        onRequestClose={this.props.onRequestClose}
        style={customStyles}
        contentLabel='create account modal'
        shouldCloseOnOverlayClick={false}
      >
        <ExportContainer>
          <Icon name='Close' onClick={this.props.onRequestClose} />
          <h4>Export</h4>
          <RadioButtonsCointaner>
            <RadioButton
              checked={this.state.exportType === 'all'}
              label={'All'}
              onClick={this.onClickRadioButton('all')}
            />
            <RadioButton
              checked={this.state.exportType === 'current'}
              label={'Current Search Result'}
              onClick={this.onClickRadioButton('current')}
            />
          </RadioButtonsCointaner>
          <FormatExportContainer>
            <FormatHeader>Format</FormatHeader>
            <Checkbox label={'PDF'} />
            <Checkbox label={'XLS'} />
            <Checkbox label={'CSV'} />
          </FormatExportContainer>
          <ExportButton size='small'>Export</ExportButton>
        </ExportContainer>
      </Modal>
    )
  }
}

export default ExportModal
