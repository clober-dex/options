import fs from 'fs'
import path from 'path'

import { NETWORK } from '../utils/constant'
const BASE = './deployments'
const DESTINATION = './deployments/share'

const assert = require('assert')

;(() => {
  const basePath = path.join(__dirname, '../', BASE)
  assert(fs.existsSync(basePath))
  const baseDestPath = path.join(__dirname, '../', DESTINATION)
  if (!fs.existsSync(baseDestPath)) {
    fs.mkdirSync(baseDestPath)
  }
  const existDirectories = fs
    .readdirSync(basePath, { withFileTypes: true })
    .filter((item) => item.isDirectory())
    .map((item) => item.name)
  const NETWORKS = Object.values(NETWORK).filter((x) =>
    existDirectories.includes(x),
  )
  for (const network of NETWORKS) {
    const targetDir = path.join(basePath, network)
    if (!fs.existsSync(targetDir)) {
      continue
    }
    const destDir = path.join(baseDestPath, network)
    if (!fs.existsSync(destDir)) {
      fs.mkdirSync(destDir)
    }
    fs.readdirSync(targetDir)
      .filter((name) => path.extname(name) === '.json')
      .map((name) => {
        const json = require(path.join(targetDir, name))
        return {
          name,
          content: { address: json.address, abi: json.abi },
        }
      })
      .forEach((file) =>
        fs.writeFileSync(
          path.join(destDir, file.name),
          JSON.stringify(file.content, null, 2),
          'utf8',
        ),
      )
  }
})()
