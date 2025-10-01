/* eslint-disable */
/* tslint:disable */

/**
 * Mock Service Worker (2.11.3).
 * @see https://github.com/mswjs/msw
 * - Please do NOT modify this file.
 * - Please do NOT serve this file on production.
 */

const INTEGRITY_CHECKSUM = 'c5f7f8e3f2a1d9c8b7a6e5f4d3c2b1a0'
const IS_MOCKED_RESPONSE = Symbol('isMockedResponse')
const activeClientIds = new Set()

self.addEventListener('install', function () {
  self.skipWaiting()
})

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim())
})

self.addEventListener('message', async function (event) {
  const clientId = event.source.id

  if (!clientId || !event.data) {
    return
  }

  const allClients = await self.clients.matchAll({
    type: 'window',
  })

  switch (event.data) {
    case 'KEEPALIVE_REQUEST': {
      sendToClient(clientId, {
        type: 'KEEPALIVE_RESPONSE',
      })
      break
    }

    case 'INTEGRITY_CHECK_REQUEST': {
      sendToClient(clientId, {
        type: 'INTEGRITY_CHECK_RESPONSE',
        payload: INTEGRITY_CHECKSUM,
      })
      break
    }

    case 'MOCK_ACTIVATE': {
      activeClientIds.add(clientId)

      sendToClient(clientId, {
        type: 'MOCKING_ENABLED',
        payload: true,
      })
      break
    }

    case 'MOCK_DEACTIVATE': {
      activeClientIds.delete(clientId)
      break
    }

    case 'CLIENT_CLOSED': {
      activeClientIds.delete(clientId)

      const remainingClients = allClients.filter((client) => {
        return client.id !== clientId
      })

      if (remainingClients.length === 0) {
        self.registration.unregister()
      }

      break
    }
  }
})

self.addEventListener('fetch', function (event) {
  const { request } = event
  const requestId = crypto.randomUUID()

  return event.respondWith(
    handleRequest(event, requestId).catch((error) => {
      console.error(
        '[MSW] Failed to mock a "%s" request to "%s": %s',
        request.method,
        request.url,
        error
      )
    })
  )
})

async function handleRequest(event, requestId) {
  const { request } = event
  const clientId = event.clientId || event.resultingClientId

  if (!clientId || !activeClientIds.has(clientId)) {
    return fetch(request)
  }

  const requestClone = request.clone()

  sendToClient(clientId, {
    type: 'REQUEST',
    payload: {
      id: requestId,
      url: request.url,
      method: request.method,
      headers: Object.fromEntries(request.headers.entries()),
      cache: request.cache,
      mode: request.mode,
      credentials: request.credentials,
      destination: request.destination,
      integrity: request.integrity,
      redirect: request.redirect,
      referrer: request.referrer,
      referrerPolicy: request.referrerPolicy,
      body: await request.text(),
      bodyUsed: request.bodyUsed,
      keepalive: request.keepalive,
    },
  })

  return new Promise((resolve) => {
    addEventListener('message', async function resolver(event) {
      if (
        event.source?.id !== clientId ||
        event.data?.type !== 'RESPONSE' ||
        event.data?.payload?.id !== requestId
      ) {
        return
      }

      removeEventListener('message', resolver)

      const response = event.data.payload

      if (response.type === 'error') {
        resolve(fetch(requestClone))
        return
      }

      const mockedResponse = new Response(response.body, {
        ...response,
        headers: new Headers(response.headers),
      })

      Reflect.defineProperty(mockedResponse, IS_MOCKED_RESPONSE, {
        value: true,
        enumerable: true,
      })

      resolve(mockedResponse)
    })
  })
}

function sendToClient(clientId, message) {
  return new Promise((resolve, reject) => {
    const channel = new MessageChannel()

    channel.port1.onmessage = (event) => {
      if (event.data && event.data.error) {
        return reject(event.data.error)
      }

      resolve(event.data)
    }

    self.clients
      .get(clientId)
      .then((client) => {
        if (!client) {
          return
        }

        client.postMessage(message, [channel.port2])
      })
      .catch(reject)
  })
}
