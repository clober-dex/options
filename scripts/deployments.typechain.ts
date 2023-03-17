import path from 'path'
import fs from 'fs'
import { exec } from 'child_process'

import { NETWORK } from '../utils/constant'
const BASE = './deployments'
const DESTINATION = './deployments/share-typechain'
const TYPECHAIN_DESTINATION = './deployments/share-typechain/typechain'

const assert = require('assert')

;(() => {
  const baseDeploymentsPath = path.join(__dirname, '../', BASE)
  assert(fs.existsSync(baseDeploymentsPath))
  const baseDestPath = path.join(__dirname, '../', DESTINATION)
  if (!fs.existsSync(baseDestPath)) {
    fs.mkdirSync(baseDestPath)
  }
  const existDirectories = fs
    .readdirSync(baseDeploymentsPath, { withFileTypes: true })
    .filter((item) => item.isDirectory())
    .map((item) => item.name)
  const NETWORKS = Object.values(NETWORK).filter((x) =>
    existDirectories.includes(x),
  )
  for (const network of NETWORKS) {
    const targetDir = path.join(baseDeploymentsPath, network)
    if (!fs.existsSync(targetDir)) {
      continue
    }
    const destDir = path.join(baseDestPath, network)
    if (!fs.existsSync(destDir)) {
      fs.mkdirSync(destDir)
    }
    const addresses = fs
      .readdirSync(targetDir)
      .filter((name) => path.extname(name) === '.json')
      .reduce((acc, name) => {
        const json = require(path.join(targetDir, name))
        return {
          ...acc,
          [name.replace('.json', '')]: json.address,
        }
      }, {})
    fs.writeFileSync(
      path.join(destDir, 'address.json'),
      JSON.stringify(addresses, null, 2),
      'utf8',
    )
  }

  const typechainBaseDestPath = path.join(
    __dirname,
    '../',
    TYPECHAIN_DESTINATION,
  )
  exec(
    `npx typechain --target ethers-v5 deployments/${NETWORKS[0]}/*.json --out-dir ${typechainBaseDestPath}`,
  )
})()
