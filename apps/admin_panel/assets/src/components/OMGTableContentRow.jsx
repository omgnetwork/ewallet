import React from 'react';
import PropTypes from 'prop-types';
import OMGTruncatedCell from './OMGTruncatedCell';

const OMGTableContentRow = ({ data, shortenedColumnIndexes }) => {
  const tds = Object.values(data)
    .map(v => `${v}`)
    .map((content, index) => (
      <td key={index}>
        {shortenedColumnIndexes.includes(index) ?
          <OMGTruncatedCell content={content} /> : content
        }
      </td>
    ));
  return (
    <tr>
      {tds}
    </tr>
  );
};

OMGTableContentRow.propTypes = {
  data: PropTypes.object.isRequired,
  shortenedColumnIndexes: PropTypes.arrayOf(PropTypes.number).isRequired,
};

export default OMGTableContentRow;
