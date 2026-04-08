const AWS_CONFIG = {
  region: "${region}",
  userPoolId: "${user_pool_id}",
  userPoolWebClientId: "${client_id}",
  apiEndpoint: "${api_url}",
  cloudFrontDomain: "${cloudfront_domain}",
};

window.AWS_CONFIG = AWS_CONFIG;