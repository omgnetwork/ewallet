import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Button, Modal } from 'react-bootstrap';
import DialogActions from '../actions/dialog.actions';

class OMGDialog extends Component {
  constructor(props) {
    super(props);
    this.handleCancel = this.handleCancel.bind(this);
    this.handleConfirm = this.handleConfirm.bind(this);
  }


  handleConfirm() {
    const { hide } = this.props;
    const { handleClickOk } = this.props;
    handleClickOk();
    hide();
  }

  handleCancel() {
    const { hide } = this.props;
    const { handleClickCancel } = this.props;
    hide();
    handleClickCancel();
  }

  render() {
    const { text } = this.props;
    const {
      title, body, ok, cancel,
    } = text;
    const { isShow } = this.props;
    return (
      <div className="static-modal">
        <Modal show={isShow}>
          <Modal.Header closeButton onHide={this.handleCancel}>
            <Modal.Title>
              {title}
            </Modal.Title>
          </Modal.Header>
          <Modal.Body>
            {body}
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={this.handleCancel}>
              {cancel}
            </Button>
            <Button bsStyle="primary" onClick={this.handleConfirm}>
              {ok}
            </Button>
          </Modal.Footer>
        </Modal>
      </div>
    );
  }
}

function mapDispatchToProps(dispatch) {
  return {
    hide: () => dispatch(DialogActions.hide()),
  };
}


OMGDialog.propTypes = {
  handleClickCancel: PropTypes.func,
  handleClickOk: PropTypes.func,
  hide: PropTypes.func.isRequired,
  isShow: PropTypes.bool,
  text: PropTypes.shape({
    title: PropTypes.string.isRequired,
    body: PropTypes.string.isRequired,
    ok: PropTypes.string.isRequired,
    cancel: PropTypes.string.isRequired,
  }).isRequired,
};

OMGDialog.defaultProps = {
  handleClickOk: () => { },
  handleClickCancel: () => { },
  isShow: false,
};

export default connect(null, mapDispatchToProps)(OMGDialog);
