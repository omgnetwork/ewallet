import React, { Component } from 'react';
import PropTypes from 'prop-types';
import OMGCircleButton from './OMGCircleButton';
import Placeholder from '../../public/images/user_icon_placeholder.png';

const defaultProps = {
  img: Placeholder,
  containerClass: 'omg_photo_uploader',
  imgClass: 'omg_photo_uploader__img',
  showUploadBtn: true,
  showCloseBtn: false,
};

const propTypes = {
  containerClass: PropTypes.string,
  img: PropTypes.string,
  imgClass: PropTypes.string,
  onFileChanged: PropTypes.func.isRequired,
  showCloseBtn: PropTypes.bool,
  showUploadBtn: PropTypes.bool,
};

class OMGPhotoPreviewer extends Component {
  constructor(props) {
    super(props);
    const { img, showCloseBtn, showUploadBtn } = this.props;
    this.state = {
      file: null,
      img,
      showUploadBtn,
      showCloseBtn,
    };
    this.handleChangeImg = this.handleChangeImg.bind(this);
    this.handleBrowseImg = this.handleBrowseImg.bind(this);
    this.handleRemoveImg = this.handleRemoveImg.bind(this);
  }

  handleChangeImg(e) {
    const reader = new FileReader();
    const file = e.target.files[0];
    const { onFileChanged } = this.props;

    reader.onloadend = () => {
      this.setState(
        {
          file,
          img: reader.result,
          showUploadBtn: false,
          showCloseBtn: true,
        },
        () => onFileChanged(file),
      );
    };

    reader.readAsDataURL(file);
  }

  handleBrowseImg(e) {
    document.getElementById('file-input').click();
  }

  handleRemoveImg(e) {
    const { img } = this.props;
    const { onFileChanged } = this.props;
    document.getElementById('file-input').value = null;
    this.setState(
      {
        file: null,
        img: Placeholder,
        showUploadBtn: true,
        showCloseBtn: false,
      },
      () => onFileChanged(null),
    );
  }

  render() {
    const { containerClass, imgClass } = this.props;
    const { img, showUploadBtn, showCloseBtn } = this.state;

    return (
      <div className={`${containerClass}`}>
        <img alt="placeholder" className={`${imgClass}`} src={img} />
        <OMGCircleButton
          className="omg_photo_uploader__top-right-button"
          faName="close"
          onClick={this.handleRemoveImg}
          show={showCloseBtn}
          size="small"
        />
        <OMGCircleButton
          className="omg_photo_uploader__center-button"
          faName="camera"
          onClick={this.handleBrowseImg}
          show={showUploadBtn}
          size="medium"
        />
        <input
          accept="image/*"
          id="file-input"
          onChange={this.handleChangeImg}
          style={{ display: 'none' }}
          type="file"
        />
      </div>
    );
  }
}

OMGPhotoPreviewer.defaultProps = defaultProps;
OMGPhotoPreviewer.propTypes = propTypes;

export default OMGPhotoPreviewer;
