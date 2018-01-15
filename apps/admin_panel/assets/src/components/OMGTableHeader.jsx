import React from 'react';
import PropTypes from 'prop-types';
import CaretUp from '../../public/images/caret_up.png';
import CaretDown from '../../public/images/caret_down.png';
import Default from '../../public/images/caret_default.png';

const sortingMode = ['asc', 'desc', 'default'];
const nextSort = mode => (mode === 'asc' ? 'desc' : 'asc');

const OMGTableHeader = ({
  sortBy, title, position, handleClick,
}) => {
  let sortIcon;
  switch (sortBy) {
    case 'asc':
      sortIcon = CaretDown;
      break;
    case 'desc':
      sortIcon = CaretUp;
      break;
    default:
      sortIcon = Default;
  }

  return (
    <th className="omg-header-button" onClick={() => handleClick(position, nextSort(sortBy))}>
      {title}
      <img alt="Caret" height={24} src={sortIcon} width={24} />
    </th>
  );
};

OMGTableHeader.defaultProps = {
  sortBy: 'default',
};

OMGTableHeader.propTypes = {
  handleClick: PropTypes.func.isRequired,
  position: PropTypes.number.isRequired,
  sortBy: PropTypes.oneOf(sortingMode),
  title: PropTypes.string.isRequired,
};

export default OMGTableHeader;
