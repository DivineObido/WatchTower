import dotenv from 'dotenv'
import createNextApp from 'next'
import nextBuild from 'next/dist/build'
import path from 'path'

dotenv.config({
  path: path.resolve(__dirname, '../.env'),
})

import express from 'express'
import payload from 'payload'

import { seed } from './payload/seed'

const app = express()
const PORT = process.env.PORT || 80

const start = async (): Promise<void> => {
  await payload.init({
    secret: process.env.PAYLOAD_SECRET || '',
    express: app,
    onInit: () => {
      console.log('PAYLOAD INIT RAN')
      payload.logger.info(`Payload Admin URL: ${payload.getAdminURL()}`)
    },
  })

  if (process.env.PAYLOAD_SEED === 'true') {
    await seed(payload)
    process.exit()
  }

  if (process.env.NEXT_BUILD) {
    app.listen(PORT, async () => {
      payload.logger.info(`Next.js is now building...`)
      // @ts-expect-error
      await nextBuild(path.join(__dirname, '../'))
      process.exit()
    })

    return
  }

  const nextApp = createNextApp({
    dev: process.env.NODE_ENV !== 'production',
    dir: path.join(__dirname, '../'),
  })

  const nextHandler = nextApp.getRequestHandler()

  app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok' })
  })

  nextApp.prepare().then(() => {
    payload.logger.info('Starting Next.js...')

    app.get('*', (req, res) => nextHandler(req, res))

    app.listen(PORT, async () => {
      payload.logger.info(`Next.js App URL: ${process.env.PAYLOAD_PUBLIC_SERVER_URL}`)
    })
  })
}

start()
