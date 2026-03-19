# GOMZ Club Contracts

Cleaned Hardhat repository for the `GOMZ Club` ERC721A-based NFT collection contract.

This repository started from an old `ERC721A_GOMZ` fork and has been reorganized into a project-specific contract repo with:

- a dedicated `GomzClubCollection` mint contract
- whitelist and public sale phases
- placeholder and reveal metadata flow
- owner reserve minting
- deployment and test coverage

## Project Context

`GOMZ Club` presented itself as an NFT donation project that launched in 2022. The original public site is still online and explicitly references:

- the `GOMZ CLUB` brand
- a donation-oriented NFT project
- the `김건희 NFT` keyword in site metadata

Reference:

- [GOMZ Club website](https://gomz.club/)

This repository is intended to preserve and modernize the contract-side engineering artifact from that project in a cleaner, more maintainable form.

## Historical Press Coverage

The launch campaign received Korean media coverage, including Naver-hosted news pages:

- [국민일보: 김건희 ‘곰 캐릭터’ NFT도 등장…“경매 수익 전액 기부”](https://n.news.naver.com/mnews/article/005/0001523763?sid=100)
- [서울경제: [단독]김건희 NFT 1.25ETH 낙찰…2호 정용진은 얼마 될까?](https://n.news.naver.com/mnews/article/011/0004054476?sid=101)
- [매일경제: "357만원부터, 수익 전액 기부"…경매 올라온 김건희 여사 캐릭터 '화제'](https://n.news.naver.com/mnews/article/009/0004959604?sid=102)

These links are included as historical context for the public launch and related donation NFT campaign, not as an endorsement of any political position.

## Contract Summary

`contracts/GomzClubCollection.sol` implements:

- `MAX_SUPPLY = 2022`
- `WHITELIST_SUPPLY_CAP = 1200`
- `OWNER_RESERVE_CAP = 600`
- `MAX_PER_WALLET = 5`
- `MAX_PER_TX = 3`
- exact-price whitelist and public ETH minting
- owner-managed whitelist seeding
- hidden metadata before reveal
- base URI plus `.json` extension after reveal

The contract starts token IDs at `1`.

## Project Layout

```text
contracts/
  ERC721A.sol
  IERC721A.sol
  GomzClubCollection.sol

scripts/
  deploy.js

test/
  GomzClubCollection.test.js
```

## Quick Start

```bash
npm install
npm run compile
npm test
```

## Deploy

Set `DEPLOYER_KEY` and optionally `PLACEHOLDER_URI`, then run:

```bash
npx hardhat run scripts/deploy.js --network <network-name>
```

Example:

```bash
export DEPLOYER_KEY=0x...
export PLACEHOLDER_URI=https://gomz.club/metadata/hidden.json
npx hardhat run scripts/deploy.js --network goerli
```

## Notes

- This repo now focuses only on the project contract and supporting files.
- The old generic ERC721A upstream docs and test matrix were removed to make the repository easier to understand as a standalone collection contract.
- ERC721A attribution is preserved in the included library source headers.
