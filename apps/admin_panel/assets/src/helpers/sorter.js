/* eslint import/prefer-default-export: 0 */
export const byCreatedAtAsc = (d1, d2) => new Date(d1.created_at) - new Date(d2.created_at);
