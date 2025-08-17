import { describe, expect, it } from 'vitest';

// These are globally provided by the vitest-environment-clarinet setup.
declare const simnet: any;
declare const types: any;

const CONTRACT_NAME_NFT = 'dynamic-nft';
const CONTRACT_NAME_RARE = 'rare-token';

describe("Dynamic NFT evolution (Tx version)", () => {
  it("buys NFT and evolves on activity thresholds", () => {
    const user = simnet.wallet_1 ?? simnet.deployer;
    const nftId = `${simnet.deployer}.${CONTRACT_NAME_NFT}`;

    // Buy NFT - expect (ok u1) for the first mint
    let receipt = simnet.callPublicFn(nftId, "buy-nft", [], user.address);
    receipt.result.expectOk().expectUint(1);

    // Get the token ID for the user
    const tidResult = simnet.callReadOnlyFn(nftId, "get-user-token", [types.principal(user.address)], user.address);
    const tokenId = tidResult.result.expectOk().expectUint();

    // Initially stage 1
    let stage = simnet.callReadOnlyFn(nftId, "get-token-stage", [types.uint(tokenId)], user.address);
    stage.result.expectOk().expectUint(1);

    // Record 3 activities -> stage 2
    for (let i = 0; i < 3; i++) {
      const r = simnet.callPublicFn(nftId, "record-activity", [], user.address);
      r.result.expectOk();
    }

    stage = simnet.callReadOnlyFn(nftId, "get-token-stage", [types.uint(tokenId)], user.address);
    stage.result.expectOk().expectUint(2);

    // Record up to 10 -> stage 3
    const more = 7;
    for (let i = 0; i < more; i++) {
      const r = simnet.callPublicFn(CONTRACT_NFT, "record-activity", [], user.address);
      r.result.expectOk();
    }

    stage = simnet.callReadOnlyFn(CONTRACT_NFT, "get-token-stage", [types.uint(tokenId)], user.address);
    stage.result.expectOk().expectUint(3);

    // Token URI returns SVG data URI
    const uri = simnet.callReadOnlyFn(nftId, "get-token-uri", [types.uint(tokenId)], user.address);
    const val = uri.result.expectOk().expectAscii();
    expect(val.startsWith("data:image/svg+xml;utf8,")).toBe(true);
  });

  it("burns rare token to evolve stages", () => {
    const user = simnet.wallet_2 ?? simnet.deployer;
    const nftId = `${simnet.deployer}.${CONTRACT_NAME_NFT}`;
    const rareId = `${simnet.deployer}.${CONTRACT_NAME_RARE}`;

    // Buy NFT
    let receipt = simnet.callPublicFn(CONTRACT_NFT, "buy-nft", [], user.address);
    receipt.result.expectOk();

    // Get the token ID for the user
    const tidResult = simnet.callReadOnlyFn(CONTRACT_NFT, "get-user-token", [types.principal(user.address)], user.address);
    const tokenId = tidResult.result.expectOk().expectUint();

    // Buy 2 rare tokens
    receipt = simnet.callPublicFn(rareId, "buy-rare", [types.uint(2)], user.address);
    receipt.result.expectOk();

    // Evolve twice using rare token burns
    for (let i = 0; i < 2; i++) {
      const r = simnet.callPublicFn(nftId, "evolve-with-rare", [], user.address);
      r.result.expectOk();
    }

    // Check stage 3
    const stage = simnet.callReadOnlyFn(nftId, "get-token-stage", [types.uint(tokenId)], user.address);
    stage.result.expectOk().expectUint(3);
  });
});
