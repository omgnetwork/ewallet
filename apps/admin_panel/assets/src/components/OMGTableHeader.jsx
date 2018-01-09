import React from 'react';
import PropTypes from 'prop-types';
import CaretUp from '../../public/images/caret_up.svg';
import CaretDown from '../../public/images/caret_down.svg';
import Default from '../../public/images/caret_default.png';

const sortingMode = ['asc', 'desc', 'default'];
const nextSort = mode => sortingMode[(sortingMode.indexOf(mode) + 1) % sortingMode.length];

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
      <img alt="Caret" src={sortIcon} width={24} />
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
