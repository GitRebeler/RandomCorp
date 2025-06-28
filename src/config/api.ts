// API configuration
export const getApiBaseUrl = (): string => {
  // Use environment variable if available, otherwise fallback to relative URLs for ingress
  return process.env.REACT_APP_API_URL || '/api';
};

export const buildApiUrl = (endpoint: string): string => {
  const baseUrl = getApiBaseUrl();
  
  // If using relative URL (ingress setup), ensure proper path construction
  if (baseUrl.startsWith('/')) {
    // Remove leading slash from endpoint to avoid double slashes
    const normalizedEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    // Ensure base URL ends with slash for proper concatenation
    const normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : `${baseUrl}/`;
    return `${normalizedBaseUrl}${normalizedEndpoint}`;
  }
  
  // For absolute URLs (development/legacy), use original logic
  if (!baseUrl) {
    return endpoint;
  }
  
  // Ensure endpoint starts with /
  const normalizedEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  
  // Remove trailing slash from base URL and combine
  const normalizedBaseUrl = baseUrl.replace(/\/$/, '');
  
  return `${normalizedBaseUrl}${normalizedEndpoint}`;
};
