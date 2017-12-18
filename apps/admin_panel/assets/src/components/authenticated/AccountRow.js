import React, { Component } from "react";

const AccountRow = (props) => {
	const { account } = props
	return (
		<tr key={account.id}>
			<td>{account.id}</td>
			<td>{account.name}</td>
			<td>{account.master ? "true" : "false"}</td>
			<td>{account.description}</td>
		</tr>
	)
}
export default AccountRow