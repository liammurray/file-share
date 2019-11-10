
export async function handler(event) {
  console.log(`EdgeLambda (event): ${JSON.stringify(event, null, 2)}`)

  // Get request and request headers
  const request = event.Records[0].cf.request
  const headers = request.headers

  // Configure authentication (TODO dynamo, etc.)
  const authUser = 'bok'
  const authPass = 'choy'

  // Construct the Basic Auth string
  const authString =
    'Basic ' + new Buffer(authUser + ':' + authPass).toString('base64')

  // Require Basic authentication
  if (
    typeof headers.authorization == 'undefined' ||
    headers.authorization[0].value != authString
  ) {
    const body = 'Unauthorized'
    const response = {
      status: '401',
      statusDescription: 'Unauthorized',
      body: body,
      headers: {
        'www-authenticate': [{ key: 'WWW-Authenticate', value: 'Basic' }],
      },
    }
    return response
  }
  return request
}
