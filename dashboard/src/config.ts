/** Set `VITE_USE_MOCK_DATA=true` in `.env` for sample map/stats without Firestore. */
export const useMockData = import.meta.env.VITE_USE_MOCK_DATA === 'true'

/**
 * Whether the mock session counts as staff. Set `VITE_MOCK_STAFF=false` to work
 * on the Access-not-enabled page: with mock data the signed-in user is staff by
 * default, so `/denied` correctly redirects to the dashboard and you can never
 * see it. Only affects mock mode.
 */
export const mockIsStaff = import.meta.env.VITE_MOCK_STAFF !== 'false'
