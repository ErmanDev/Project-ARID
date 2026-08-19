/** Flip to false in `.env` when Firestore reports should drive the dashboard. */
export const useMockData = import.meta.env.VITE_USE_MOCK_DATA !== 'false'
