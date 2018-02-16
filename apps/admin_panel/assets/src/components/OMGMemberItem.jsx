import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import { localize } from 'react-localize-redux';
import DefaultUserImg from '../../public/images/user_icon_placeholder.png';

const OMGMemberItem = ({
  currentPath, onEdit, onResend, translate, member,
}) => {
  const pendingUI = member.isPending
    ? (
      <span className="omg-member-item__pending">
        (Pending)
      </span>
    )
    : null;

  return (
    <div className="omg-member-item row">
      <div className="omg-member-item__avatar col-xs-2">
        <img alt="avatar" src={member.imageUrl || DefaultUserImg} />
      </div>
      <div className="col-xs-10">
        <div className="row omg-member-item__title">
          {member.email}
          {pendingUI}
          <Link
            className="omg-member-item__edit link-omg-blue"
            href={currentPath}
            onClick={() => (member.isPending ? onResend(member) : onEdit(member))}
            to={currentPath}
          >
            {member.isPending
              ? translate('components.omg_member_item.resend_invitation')
              : translate('components.omg_member_item.edit')}
          </Link>
        </div>
        <div className="row omg-member-item__position">
          {member.accountRole}
        </div>
      </div>
    </div>
  );
};

OMGMemberItem.propTypes = {
  currentPath: PropTypes.string,
  member: PropTypes.shape({
    email: PropTypes.string,
    imageUrl: PropTypes.string,
    isPending: PropTypes.bool,
    username: PropTypes.string,
    accountRole: PropTypes.string.isRequired,
  }),
  onEdit: PropTypes.func.isRequired,
  onResend: PropTypes.func.isRequired,
  translate: PropTypes.func.isRequired,
};

OMGMemberItem.defaultProps = {
  currentPath: '',
  member: {
    username: 'Null',
    imageUrl: DefaultUserImg,
    isPending: false,
  },
};

export default localize(OMGMemberItem, 'locale');
