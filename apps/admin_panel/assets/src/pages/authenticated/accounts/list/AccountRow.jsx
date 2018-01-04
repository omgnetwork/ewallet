import React from 'react';
import PropTypes from 'prop-types';

const AccountRow = (props) => {
  const { account } = props;
  return (
    <tr key={account.id}>
      <td>{account.id}</td>
      <td>{account.name}</td>
      <td>{account.master ? 'true' : 'false'}</td>
      <td>{account.description}</td>
    </tr>
  );
};

AccountRow.propTypes = {
  account: PropTypes.shape({
    id: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
    master: PropTypes.bool,
    description: PropTypes.string,
  }).isRequired,
};

export default AccountRow;
