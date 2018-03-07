import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';
import { localize } from 'react-localize-redux';
import DefaultUserImg from '../../public/images/user_icon_placeholder.png';

const OMGMemberItem = ({
  currentPath, onEdit, translate, member,
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
          {member.username || 'Null'}
          {pendingUI}
          <Link
            className="omg-member-item__edit link-omg-blue"
            href={currentPath}
            onClick={() => !member.isPending && onEdit(member)}
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
  currentPath: PropTypes.string.isRequired,
  member: PropTypes.shape({
    imageUrl: PropTypes.string,
    isPending: PropTypes.bool,
    username: PropTypes.string,
    accountRole: PropTypes.string.isRequired,
  }),
  onEdit: PropTypes.func,
  translate: PropTypes.func.isRequired,
};

OMGMemberItem.defaultProps = {
  member: {
    username: 'Null',
    imageUrl: DefaultUserImg,
    isPending: false,
  },
  onEdit: () => { },
};

export default localize(OMGMemberItem, 'locale');
