# Clober option contracts

[![Docs](https://img.shields.io/badge/docs-%F0%9F%93%84-blue)](https://docs.clober.io/)
[![codecov](https://codecov.io/gh/clober-dex/arbitrum-put-options/branch/dev/graph/badge.svg?token=QNSGDYQOL7)](https://codecov.io/gh/clober-dex/arbitrum-put-options)
[![CI status](https://github.com/clober-dex/arbitrum-put-options/actions/workflows/ci.yaml/badge.svg)](https://github.com/clober-dex/arbitrum-put-options/actions/workflows/ci.yaml)
[![Discord](https://img.shields.io/static/v1?logo=discord&label=discord&message=Join&color=blue)](https://discord.gg/clober)
[![Twitter](https://img.shields.io/static/v1?logo=twitter&label=twitter&message=Follow&color=blue)](https://twitter.com/CloberDEX)

Option Contract of Clober DEX in Arbitrum

## Table of Contents

- [Clober](#clober)
    - [Table of Contents](#table-of-contents)
    - [Deployments](#deployments)
    - [Install](#install)
    - [Usage](#usage)
        - [Unit Tests](#unit-tests)
        - [Coverage](#coverage)
        - [Linting](#linting)
    - [Licensing](#licensing)

## Deployments

### Deployments By EVM Chain(Arbitrum)

|                         | Address                                                                                                                     |  
|-------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| `Arbitrum$0_5PutOption` | [`0x0e7fc8F067470424589Cc25DceEd0dA9a1a8E72A`](https://arbiscan.io/address/0x0e7fc8F067470424589Cc25DceEd0dA9a1a8E72A#code) |
| `Arbitrum$1PutOption`   | [`0x4ed2804b5409298290654D665619c7b092297dB2`](https://arbiscan.io/address/0x4ed2804b5409298290654D665619c7b092297dB2#code) |
| `Arbitrum$2PutOption`   | [`0x9d940825498Ac26182bb682491544EcFDb74FDe0`](https://arbiscan.io/address/0x9d940825498Ac26182bb682491544EcFDb74FDe0#code) |
| `Arbitrum$4PutOption`   | [`0x1C37b78A9aacaF5CD418481C2cB8859555A75C5F`](https://arbiscan.io/address/0x1C37b78A9aacaF5CD418481C2cB8859555A75C5F#code) |
| `Arbitrum$8PutOption`   | [`0xb3fBFA4047BB1dd8bD354E3D6E15E94c75E62178`](https://arbiscan.io/address/0xb3fBFA4047BB1dd8bD354E3D6E15E94c75E62178#code) |
| `Arbitrum$16PutOption`  | [`0x9f17503a60830a660AB059a7E7eacA1E7e8C4eFD`](https://arbiscan.io/address/0x9f17503a60830a660AB059a7E7eacA1E7e8C4eFD#code) |

## Install

To install dependencies and compile contracts:

### Prerequisites
- We use [Forge Foundry](https://github.com/foundry-rs/foundry) for test. Follow the [guide](https://github.com/foundry-rs/foundry#installation) to install Foundry.

### Installing From Source

```bash
git clone https://github.com/clober-dex/arbitrum-put-options && cd arbitrum-put-options
npm install
```

## Usage

### Unit tests
```bash
npm run test
```

### Coverage
To run coverage profile:
```bash
npm run coverage:local
```

To run lint fixes:
```bash
npm run prettier:fix:ts
npm run lint:fix:sol
```

## Licensing

- The primary license for Clober Core is the Time-delayed Open Source Software Licence, see [License file](LICENSE.pdf).
- All files in [`contracts/interfaces`](contracts/interfaces) may also be licensed under GPL-2.0-or-later (as indicated in their SPDX headers), see [LICENSE_AGPL](contracts/interfaces/LICENSE_APGL).
