/** Flip to false in `.env` when Firestore reports should drive the dashboard. */
export const useMockData = import.meta.env.VITE_USE_MOCK_DATA !== 'false'

/**
 * Whether the mock session counts as staff. Set `VITE_MOCK_STAFF=false` to work
 * on the Access-not-enabled page: with mock data the signed-in user is staff by
 * default, so `/denied` correctly redirects to the dashboard and you can never
 * see it. Only affects mock mode.
 */
export const mockIsStaff = import.meta.env.VITE_MOCK_STAFF !== 'false'
