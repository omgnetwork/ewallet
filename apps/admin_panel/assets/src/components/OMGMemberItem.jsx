import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { localize } from 'react-localize-redux';

class OMGMemberItem extends Component {
  constructor(props) {
    super(props);
    this.state = {
      // isEdit: false, // Prepare for editing the member item mode to toggle an UI.
    };
  }

  render() {
    const {
      name, position, imageUrl, isPending, translate,
    } = this.props;

    const pendingUI = isPending ? (
      <span className="omg-member-item__pending">
        (Pending)
      </span>
    ) : null;

    return (
      <div className="omg-member-item row">
        <div className="omg-member-item__avatar col-xs-2">
          <img alt="avatar" src={imageUrl} />
        </div>
        <div className="col-xs-10">
          <div className="row omg-member-item__title">
            {name}
            {pendingUI}
            <a className="omg-member-item__edit" href={`#${isPending ? 'resend' : 'edit'}`}>
              {isPending ? translate('components.omg_member_item.resend_invitation') : translate('components.omg_member_item.edit')}
            </a>
          </div>
          <div className="row omg-member-item__position">
            {position}
          </div>
        </div>
      </div>
    );
  }
}

OMGMemberItem.propTypes = {
  imageUrl: PropTypes.string.isRequired,
  isPending: PropTypes.bool,
  name: PropTypes.string.isRequired,
  position: PropTypes.string.isRequired,
  translate: PropTypes.func.isRequired,
};

OMGMemberItem.defaultProps = {
  isPending: false,
};

export default localize(OMGMemberItem, 'locale');
