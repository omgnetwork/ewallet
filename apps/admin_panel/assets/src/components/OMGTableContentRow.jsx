import React from 'react';
import PropTypes from 'prop-types';

const propTypes = {
  data: PropTypes.object.isRequired,
};

const OMGTableContentRow = ({ data }) => {
  const tds = Object.values(data)
    .map(v => `${v}`)
    .map((content, index) => (
      <td key={index}>
        {content}
      </td>
    ));
  return (
    <tr>
      {tds}
    </tr>
  );
};

OMGTableContentRow.propTypes = propTypes;

export default OMGTableContentRow;
