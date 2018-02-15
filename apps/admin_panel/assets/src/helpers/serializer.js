const SERIALIZER = {
  DATA: onSuccess => result => onSuccess(result.data),
  LIST_ADMINS: onSuccess => (result) => {
    const resp = {
      data: result.data.map(admin => ({
        id: admin.id,
        email: admin.email,
        created_at: admin.created_at,
        updated_at: admin.updated_at,
      })),
      pagination: result.pagination,
    };
    onSuccess(resp);
  },
  LIST_MEMBER: onSuccess => (result) => {
    const resp = {
      data: result.data.map(member => ({
        id: member.id,
        username: member.username,
        email: member.email,
        status: member.status,
        accountRole: member.account_role,
      })),
      pagination: result.pagination,
    };
    onSuccess(resp.data);
  },
  SEARCH_USERS: onSuccess => (result) => {
    const resp = {
      data: result.data.map(member => ({
        id: member.id,
        username: member.username,
        email: member.email,
      })),
      pagination: result.pagination,
    };
    onSuccess(resp.data);
  },
  UPDATE_ACCOUNT: onSuccess => (result) => {
    onSuccess({
      updateAccount: result,
    });
  },
  NOTHING: onSuccess => () => onSuccess(),
};

export default SERIALIZER;
