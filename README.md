# Dynamic NFT on Stacks (Testnet)

## 1. Project Title

Dynamic NFT with Activity-Based Evolution on Stacks

## 2. Project Description

This project implements a dynamic, upgradable NFT system on the Stacks blockchain:

- The NFT starts at Stage 1 and evolves to higher stages (2 and 3) based on user actions.
- Two evolution paths are supported:
  - Activity-based evolution via a public function that records user activity and increments stage thresholds.
  - Utility-token burn-based evolution via an auxiliary "rare token" contract.
- Each stage renders a distinct on-chain SVG, returned via `get-token-uri` as a `data:image/svg+xml;utf8,...` URI.
- The project includes a minimal asset pipeline to inline SVGs into the contract using `scripts/inline-svgs.mjs`.

Key files:
- `contracts/dynamic-nft.clar` — Main NFT contract with evolution logic, ownership mappings, and token URI.
- `contracts/rare-token.clar` — Simple fungible/utility token used to trigger evolution by burning.
- `asset/` — SVG assets (optional; script will inline top 3 sorted). 
- `scripts/inline-svgs.mjs` — Inlines minified SVGs between `BEGIN_SVG_x`/`END_SVG_x` markers in `dynamic-nft.clar`.
- `tests/` — Vitest tests for minting, evolving, and token URI assertions.

## 3. Project Vision

- Make NFTs responsive to user engagement and on-chain behavior.
- Keep metadata trust-minimized by serving **on-chain** SVGs, avoiding off-chain dependencies.
- Provide an approachable, modular reference showcasing Clarinet + Clarify best practices and a simple asset pipeline.

## 4. Future Scope

- Add more stages and flexible rules (time-decay, streaks, or multi-attribute evolution).
- Introduce admin-governed or DAO-governed rule updates.
- Off-chain indexer integration to visualize activity history and stage progression.
- Batch minting and collections, with royalties and SIP-009 conformance checks.
- Wallet UI: mint, evolve, and preview token media.
- Per-token custom SVG composition (e.g., trait overlays) and JSON metadata with attributes.

## 5. Contract Addresses (Testnet)

- Deployer address: `ST2KMS23R64H7QB9QRX20SZNCHAAA9GVDQF430P8`
- Dynamic NFT: `ST2KMS23R64H7QB9QRX20SZNCHAAA9GVDQF430P8.dynamic-nft`
- Rare Token (pre-existing): `ST2KMS23R64H7QB9QRX20SZNCHAAA9GVDQF430P8.rare-token`

- <img width="1919" height="986" alt="Screenshot From 2025-08-17 15-24-23" src="https://github.com/user-attachments/assets/6e137ab2-7eb7-4501-b3ed-a870bb0cdc4c" />

<img width="1919" height="986" alt="Screenshot From 2025-08-17 15-25-25" src="https://github.com/user-attachments/assets/c8cffaf7-6bbf-4524-a144-c71973049385" />

View on Hiro Explorer (Testnet):
- Deployer: https://explorer.hiro.so/address/ST2KMS23R64H7QB9QRX20SZNCHAAA9GVDQF430P8?chain=testnet
- dynamic-nft: https://explorer.hiro.so/contract/ST2KMS23R64H7QB9QRX20SZNCHAAA9GVDQF430P8.dynamic-nft?chain=testnet
- rare-token: https://explorer.hiro.so/contract/ST2KMS23R64H7QB9QRX20SZNCHAAA9GVDQF430P8.rare-token?chain=testnet

## Getting Started

### Prerequisites
- Node.js 18+
- Clarinet (latest)

### Install
```bash
npm install
```

### Check contracts
```bash
clarinet check
```

### Run tests
```bash
npm test
```

### Inline SVGs (optional)
The contract already contains minimal SVGs under these markers in `contracts/dynamic-nft.clar`:
- `;; BEGIN_SVG_1` / `;; END_SVG_1`
- `;; BEGIN_SVG_2` / `;; END_SVG_2`
- `;; BEGIN_SVG_3` / `;; END_SVG_3`

To replace them with assets from `asset/` (top 3 sorted by filename):
```bash
node scripts/inline-svgs.mjs
```

## Development Workflow

### Local (Simnet)
- Use `clarinet console` or tests under `tests/`.
- Key functions in `dynamic-nft.clar`:
  - `buy-nft` (public): mint one NFT per user and set stage to 1.
  - `record-activity` (public): record activity; evolve when thresholds are reached.
  - `burn-to-evolve` (public): `contract-call? .rare-token burn-from-sender u1` then evolve.
  - `get-token-stage` (read-only): returns current stage of a token id.
  - `get-token-uri` (read-only): returns the stage-specific SVG as a data URI.

### Testnet Deployment
Regenerate low-cost plan and deploy:
```bash
clarinet deployments generate --testnet --low-cost
clarinet deployments apply --testnet
```
Notes:
- If `ContractAlreadyExists` for `rare-token`, remove it from the plan and deploy only `dynamic-nft`.
- In this repo, `Clarinet.toml` excludes `rare-token` to avoid re-publishing.

## Usage Examples

### From Clarinet console (testnet)
```clj
;; Get token URI for token 1
(contract-call? 'ST2KMS23R64H7QB9QRX20SZNCHAAA9GVDQF430P8.dynamic-nft get-token-uri u1)

;; Stage for token 1
(contract-call? 'ST2KMS23R64H7QB9QRX20SZNCHAAA9GVDQF430P8.dynamic-nft get-token-stage u1)
```

### From Stacks API (curl)
```bash
curl "https://api.testnet.hiro.so/v2/contracts/source/ST2KMS23R64H7QB9QRX20SZNCHAAA9GVDQF430P8/dynamic-nft"
```

## Project Structure

```
NFT/
├─ contracts/
│  ├─ dynamic-nft.clar
│  └─ rare-token.clar
├─ asset/                  # optional SVGs to inline
├─ scripts/
│  └─ inline-svgs.mjs      # replaces SVG constants between markers
├─ tests/
│  ├─ dynamic-nft.test.ts
│  └─ dynamic-nft.clean.test.ts
├─ deployments/
│  └─ default.testnet-plan.yaml
├─ Clarinet.toml
├─ package.json
└─ README.md
```

## Notes & Caveats

- The minimal SVGs are intentionally small for lower byte-cost in source.
- The testnet deployment in this repo publishes only `dynamic-nft`; it references `.rare-token` which is already deployed under the same deployer.
- Warnings from `clarinet check` about potentially unchecked data are expected in this simple reference design; production systems should add explicit checks and authorization rules.

## License

MIT (or specify your preferred license)
