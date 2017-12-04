import React from "react";

export default function Loader(props) {
  return props.show ? (
    <div>
      <p>Loading...</p>
    </div>
  ) : null;
}
