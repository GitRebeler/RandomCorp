// API configuration
export const getApiBaseUrl = (): string => {
  // Use environment variable if available, otherwise fallback to relative URLs for development
  return process.env.REACT_APP_API_URL || '';
};

export const buildApiUrl = (endpoint: string): string => {
  const baseUrl = getApiBaseUrl();
  
  // If no base URL is configured, return relative URL (for development)
  if (!baseUrl) {
    return endpoint;
  }
  
  // Ensure endpoint starts with /
  const normalizedEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  
  // Remove trailing slash from base URL and combine
  const normalizedBaseUrl = baseUrl.replace(/\/$/, '');
  
  return `${normalizedBaseUrl}${normalizedEndpoint}`;
};
